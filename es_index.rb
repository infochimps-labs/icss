#!/usr/bin/env ruby
$LOAD_PATH << './lib'
require 'rubberband'
require 'icss'

class ESIndex
  attr_accessor :client
  attr_accessor :options
  attr_accessor :index_timestamp
  
  def initialize
    @options = Settings
    @client = ElasticSearch.new(options['elasticsearch.host'])
    @index_timestamp = Time.now.to_s.downcase.gsub(/[^a-z0-9\-]+/i, '-').squeeze('-')
  end
  
  def index(type=nil)
    types = type ? [type.singularize] : %w{dataset type source license}
    types.each do |type|
      block = case type
        when "dataset"
          lambda{|protocol, hsh|
            next if (['icss.core.typedefs', 'meta.req.geolocator_typedefs'].include?(protocol.fullname) || protocol.title.blank?)
            
            if !protocol.messages.empty?
              hsh[:_type] = 'api'
            else
              hsh[:_type] = protocol[:data_assets].to_a.map(&:asset_type).first || 'offsite'
            end
            
            unless (catalog = protocol.targets[:catalog].to_a).empty?
              score = catalog.first.delete(:score).to_f 
              price = catalog.first.price.to_f
            else
              price = nil
              score = 1.0
            end
            
            score *= 5
            score += 15 unless !price || protocol.messages.empty?
            hsh[:score] = hsh[:_boost] = score
            true
          }
        when "type"
          lambda{|type, hsh| hsh[:core] = true if type.is_core?; true }
        else
          lambda{|obj, hsh| true }
      end
      index_icss(type, &block)
      cleanup_aliases(type)
    end
  end
  
  def cleanup_aliases(type)
    current_aliases = client.index_status("meta.#{type.pluralize}")["indices"].keys rescue []
    actions = { :add => { "meta.#{type.pluralize}-#{index_timestamp}" => "meta.#{type.pluralize}"}}
    actions[:remove] = current_aliases.inject({}){|hsh, index_alias| hsh[index_alias] = "meta.#{type.pluralize}"; hsh } unless current_aliases.empty?
    
    client.alias_index(actions)
    client.delete_index(current_aliases.join(',')) unless current_aliases.empty?
  end
  
  def index_icss(type, &block)
    create_index(type)
    puts "Indexing #{type.pluralize}"
    
    Icss::Meta.const_get((type =='dataset' ? 'protocol' : type).classify).all.each do |obj|
      puts "Indexing #{type}: #{obj.fullname}" if options[:verbose]
      hsh = obj.to_hash rescue obj.to_schema
      next unless yield(obj, hsh)
      client.index(hsh, {:index => "meta.#{type.pluralize}-#{index_timestamp}", :type => hsh.delete(:_type)||type, :id => obj.fullname})
    end
  end
  
  def create_index(type)
    index = "meta.#{type.pluralize}-#{index_timestamp}"
    
    puts "Creating index: #{index}"
    opts = index_options(type)
    opts[:mappings][:api] = opts[:mappings][:downloadable] = opts[:mappings][:offsite] = opts[:mappings].delete(:dataset) if type.to_s == 'dataset'
        
    client.create_index(index, opts[:index]||{})
    if opts[:mappings]
      opts[:mappings].each{|type, mapping| client.update_mapping(mapping, {:index => index, :type => type}) }
    end
  rescue ElasticSearch::RequestError => error
    puts "Error creating index: #{error}"
  end

  def delete_index(type)
    client.delete_index("meta.#{type.pluralize}-#{index_timestamp}")
  rescue ElasticSearch::RequestError
  end
  
  def index_options type
    opts = common_index_options(type)
    opts[:mappings][type.to_s.to_sym][:properties].merge!(respond_to?(:"#{type}_index_properties") ? send(:"#{type}_index_properties") : {})
    opts
  end
  
  def common_index_options type
    { :index => 
      { :analysis =>
        { :filter =>
          { :word_delimiter => 
            { :type => :word_delimiter,
              :split_on_numerics => false,
              :preserve_original => true,
              :catenate_all => true
            },
            :snowball => {
              :type => :snowball,
              :language => :English
            },
            :min_length => {
              :type => :length,
              :min => 1
            }
          },
          :analyzer => 
          { :namespaces =>
            { :type => :pattern,
              :pattern => '\.+',
              :lowercase => true
            },
            :sortable =>
            { :tokenizer => :keyword,
              :filter => [:lowercase]
            },
            :text => {
              :type => :custom,
              :tokenizer => :whitespace,
              :filter => [:snowball, :stop, :min_length, :word_delimiter, :lowercase, :shingle]
            }
          }
        }
      },
      :mappings =>
      { type.to_s.to_sym => 
        { :dynamic_templates => 
          [{ :multifield_sortable =>
            { :match => '*',
              :match_mapping_type => "string",
              :mapping => 
              { :type => :multi_field,
                :fields =>
                { :'{name}' => 
                  { :type => :string,
                    :analyzer => :text
                  },
                  :sortable =>
                  { :type => :string,
                    :analyzer => :sortable
                  }
                }
              }
            }
          }],
          :_boost => 
          { :name => :_boost,
            :null_value => 1
          },
          :_source =>
          { :excludes => [:_boost, :score, "sortable_*"],
          },
          :dynamic => true,
          :numeric_detection => true,
          :_all => { :analyzer => :text },
          :path => :full,
          :properties => {}
        }
      }
    }
  end
  
  def dataset_index_properties
    { :namespace =>
      { :type => :string,
        :analyzer => :namespaces,
        :boost => 2
      },
      :protocol =>
      { :type => :string,
        :analyzer => :namespaces,
        :boost => 2
      },
      :title =>
      { :type => :multi_field,
        :fields => {
          :title =>
          { :type => :string,
            :boost => 6,
           :analyzer => :text
          },
          :sortable =>
          { :type => :string,
            :analyzer => :sortable
          }
        }
      },
      :tags => 
      { :type => :string,
        :boost => 7,
      },
      :categories => 
      { :type => :string,
        :analyzer => :sortable
      },
      :doc => 
      { :type => :string,
        :boost => 3
      },
      :messages =>
      { :type => :object,
        :dynamic => true,
        :enabled => false,
      },
      :types => index_options(:type)[:mappings][:type],
      :data_assets =>
        { :dynamic => true,
          :properties =>
          { :md5 => 
            { :type => :string
            }
          }
        },
      :targets => 
      { :dynamic => true,
        :properties => 
        { :catalog => 
          { :dynamic => true,
            :path => :full,
            :type => :object
          },
          :geo_index => 
          { :dynamic => true,
            :properties => 
            { :sort_field => 
              { :type => :string
              }
            }
          }
        }
      }
    }
  end
  
  def type_index_properties
    { :name =>
      { :type => :string,
        :analyzer => :namespaces,
        :boost => 2
      },
      :namespace =>
      { :type => :string,
        :analyzer => :namespaces
      },
      :is_a => {
        :type => :string,
        :analyzer => :namespaces
      },
      :fields => 
      { :dynamic => true,
        :properties => 
        { :type =>
          { :enabled => false,
            :type => :object
          },
          :default => 
          { :type => :string
          },
          :identifier => 
          { :type => :string
          }
        }
      }
    }
  end
end

Settings.define 'elasticsearch.host', :env_var => 'ES_HOST', :flag => 'h', :description => 'ElasticSearch host(s)', :type => Array, :default => %w{localhost:9200}
Settings.define :verbose, :type => :boolean, :flag => 'v'
Settings.use :env_var, :commandline
Settings.resolve!

index_type = Settings.rest.first
index_type = "datasets" if index_type == "protocols"

if !Settings['elasticsearch.host'].is_a?(Array) || Settings['elasticsearch.host'].empty?
  warn "Elastic search host(s) not specified"
  exit
elsif !File.directory?(Settings[:catalog_root]||'')
  warn "Catalog root not found: #{Settings[:catalog_root]}"
  exit
elsif !(%w{datasets protocols types sources licenses} << nil).include?(index_type)
  warn "Unknown index type, should be left undefined for all, or one of: datasets, type, sources, licenses"
  exit
end

es_index = ESIndex.new
es_index.index index_type