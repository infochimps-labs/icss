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
            next if ['icss.core.typedefs', 'meta.req.geolocator_typedefs'].include? protocol.fullname
            hsh[:license] = protocol.license.to_hash if protocol.license
            hsh[:sources] = protocol.sources.inject({}){|hash, source| hash[source[0]] = source[1].to_hash; hash }
            score = nil
            score = hsh[:targets][:catalog].first.delete(:score).to_f unless protocol.targets[:catalog].to_a.empty?
            score = score.to_f == 0 ? 1 : score.to_f
            hsh[:_boost] = score * 4 
            price = protocol.targets[:catalog].first.price.to_i unless protocol.targets[:catalog].to_a.empty?
            hsh[:_boost] = hsh[:_boost].to_f + 10 unless protocol.messages.empty? || !defined?(price)
            hsh[:_messages] = hsh[:messages].map{ |key, value| value.merge({:name => key.to_s }) } unless hsh[:messages].empty?
          }
        when "type"
          lambda{|type, hsh| hsh[:core] = true if type.is_core? }
        else
          lambda{|obj, hsh| }
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
    delete_index(type)
    create_index(type)
    puts "Indexing #{type.pluralize}"
    
    Icss::Meta.const_get((type =='dataset' ? 'protocol' : type).classify).all.each do |obj|
      puts "Indexing #{type}: #{obj.fullname}" if options[:verbose]
      hsh = obj.to_hash rescue obj.to_schema
      yield obj, hsh
      client.index(hsh, {:index => "meta.#{type.pluralize}-#{index_timestamp}", :type => type, :id => obj.fullname})
    end
  end
  
  def create_index(type)
    index = "meta.#{type.pluralize}-#{index_timestamp}"
    
    puts "Creating index: #{index}"
    opts = send(:"#{type}_index_options")
    client.create_index(index, opts[:index]||{})
    client.update_mapping(opts[:mappings][type.to_sym]||{}, {:index => index, :type => type}) if opts[:mappings].present?
  rescue ElasticSearch::RequestError => error
    puts "Error creating index: #{error}"
  end

  def delete_index(type)
    client.delete_index("meta.#{type.pluralize}-#{index_timestamp}")
  rescue ElasticSearch::RequestError
  end
  
  def dataset_index_options
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
            :text => {
              :type => :custom,
              :tokenizer => :whitespace,
              :filter => [:snowball, :stop, :min_length, :word_delimiter, :lowercase, :shingle]
            }
          }
        }
      },
      :mappings =>
      { :dataset => 
        { :_boost => 
          { :name => :_boost,
            :null_value => 1
          },
          :dynamic_templates =>
          [
            { "object_full_path" => 
              { :match => '*',
                :match_mapping_type => :object,
                :mapping =>
                { :path => 'full',
                  :type => :object,
                  :dynamic => true
                }
              }
            }
          ],
          :_source =>
          { :excludes => [:_boost, :_messages],
          },
          :dynamic => true,
          :numeric_detection => true,
          :_all => { :analyzer => :text },
          :properties =>
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
            { :type => :string,
              :boost => 6,
            },
            :tags => 
            { :type => :string,
              :boost => 7,
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
            :_messages => 
            { :type => :object,
              :index_name => 'messages',
              :properties =>
              { :request =>
                { :dynamic => true,
                  :type => :object,
                  :enabled => false,
                  :properties => 
                   { :type =>
                     { :type => :object,
                       :enabled => false 
                     }
                   }
                }
              }
            },
            :types => type_index_options[:mappings][:type],
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
        }
      }
    }
  end
  
  def type_index_options
    { :index => 
      { :analysis =>
        { :analyzer => 
          { :namespaces =>
            { :type => :pattern,
              :pattern => '\.+',
              :lowercase => true
            },
          }
        }
      },
      :mappings => 
      { :type =>
        { :dynamic => true,
          :numeric_detection => true,
          :properties =>
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
        }
      }
    }
  end
  
  def source_index_options
    {}
  end
  def license_index_options
    {}
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