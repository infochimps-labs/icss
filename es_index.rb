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
    types = type ? [type.singularize] : %w{protocol type source license}
    types.each do |type|
      block = case type
        when "protocol"
          lambda{|protocol, hsh|
            next if ['icss.core.typedefs', 'meta.req.geolocator_typedefs'].include? protocol.fullname
            hsh[:license] = protocol.license.to_hash if protocol.license
            hsh[:sources] = protocol.sources.inject({}){|hash, source| hash[source[0]] = source[1].to_hash; hash }
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
    current_aliases = client.get_aliases("meta.#{type.pluralize}").keys
    actions = { :add => { "meta.#{type.pluralize}-#{index_timestamp}" => "meta.#{type.pluralize}"}}
    actions[:remove] = current_aliases.inject({}){|hsh, index_alias| hsh[index_alias] = "meta.#{type.pluralize}"; hsh } unless current_aliases.empty?
    
    client.alias_index(actions)
    client.delete_index(current_aliases.join(',')) unless current_aliases.empty?
  end
  
  def index_icss(type, &block)
    delete_index(type)
    create_index(type)
    puts "Indexing #{type.pluralize}"
    
    Icss::Meta.const_get(type.classify).all.each do |obj|
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
  
  def protocol_index_options
    { :index => 
      { :analysis =>
        { :tokenizer =>
          { :namespaces =>
            { :pattern => '\.+',
              :lowercase => true,
              :type => :pattern
            }
          },
          :filter =>
          {
            :word_delimiter => 
            {
              :type => :word_delimiter,
              :preserve_original => true,
              :catenate_words => true,
              :catenate_numbers => true
            }
          },
          :analyzer => 
          { :namespaces =>
            { :tokenizer => :namespaces,
              :type => :custom
            },
            :word_delimiter => {
              :tokenizer => :standard,
              :type => :custom,
              :filter => [:word_delimiter, :lowercase]
            }
          }
        }
      },
      :mappings =>
      { :protocol => 
        { :dynamic => true,
          :numeric_detection => true,
          :_all => { :analyzer => :word_delimiter },
          :properties =>
          { :namespace =>
            { :type => :string,
              :analyzer => :namespaces,
              :boost => 3
            },
            :protocol =>
            { :type => :string,
              :analyzer => :namespaces,
              :boost => 6
            },
            :title =>
            { :type => :string,
              :boost => 6,
              :analyzer => :word_delimiter
            },
            :tags => 
            { :type => :string,
              :boost => 5
            },
            :doc => 
            { :type => :string            },
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
              { :geo_index => 
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
        { :tokenizer =>
          { :namespaces =>
            { :pattern => '\.+',
              :lowercase => true,
              :type => :pattern
            }
          },
          :analyzer => 
          { :namespaces =>
            { :tokenizer => :namespaces,
              :type => :custom
            }
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
              :boost => 4
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
                { :type => :string,
                  :analyzer => :namespaces 
                },
                :default => 
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
index_type = "protocols" if index_type == "datasets"

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