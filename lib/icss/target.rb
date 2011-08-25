module Icss

  #
  # Instantiates an array of target objects
  #
  class TargetListFactory
    def self.receive target_info_list, target_name
      klass = "Icss::#{target_name.to_s.camelize}Target".constantize
      target_info_list.map{|target_info| klass.receive(target_info)}
    end
  end

  class Target
    include Receiver
    include Receiver::ActsAsHash
    include Gorillib::Hashlike
    #
    # Name should not be something like 'default', it should be something
    # that 'appeals' to the message name.
    #
    rcvr_accessor :name, String
  end

  class MysqlTarget < Target
    rcvr_accessor :data_assets, Array, :of => String
    rcvr_accessor :database,    String
    rcvr_accessor :table_name,  String
  end

  class ApeyeyeTarget < Target
    rcvr_accessor :code_assets, Array, :of => String
  end

  class HbaseTarget < Target
    rcvr_accessor :data_assets,     Array, :of => String
    rcvr_accessor :table_name,      String
    rcvr_accessor :column_families, Array, :of => String
    rcvr_accessor :column_family,   String
    rcvr_accessor :loader,          String
    rcvr_accessor :id_field,        String
  end

  class ElasticSearchTarget < Target
    rcvr_accessor :data_assets, Array, :of => String
    rcvr_accessor :index_name,  String
    rcvr_accessor :id_field,    String
    rcvr_accessor :object_type, String
    rcvr_accessor :loader,      String
  end

  class GeoIndexTarget < Target
    rcvr_accessor :data_assets,    Array, :of => String
    rcvr_accessor :table_name,     String
    rcvr_accessor :min_zoom,       Integer
    rcvr_accessor :max_zoom,       Integer
    rcvr_accessor :chars_per_page, Integer
    rcvr_accessor :sort_field,     String
  end

  class CatalogTarget < Target
    rcvr_accessor :name,        String
    rcvr_accessor :license,     String
    rcvr_accessor :title,       String
    rcvr_accessor :link,        String
    rcvr_accessor :description, String
    rcvr_accessor :owner,       String
    rcvr_accessor :price,       Float
    rcvr_accessor :tags,        Array, :of => String
    rcvr_accessor :messages,    Array, :of => String
    rcvr_accessor :packages,    Array, :of => Hash
  end
end
