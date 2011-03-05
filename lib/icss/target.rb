module Icss

  #
  # Instantiates an array of target objects
  #
  class TargetListFactory 
    def self.receive target_name, target_info_list
      klass = ("Icss::"+target_name.classify+"Target").constantize
      target_info_list.map{|target_info| klass.receive(target_info)}
    end
  end

  class MysqlTarget
    include Receiver
    rcvr :data_assets, Array, :of => String
    rcvr :database,    String
    rcvr :table_name,  String
  end
    
  class HbaseTarget
    include Receiver
    rcvr :data_assets,   Array, :of => String
    rcvr :database,      String
    rcvr :table_name,    String
    rcvr :column_family, String
    rcvr :loader,        String
  end

  class ElasticSearchTarget
    include Receiver
    rcvr :data_assets,   Array, :of => String
    rcvr :index_name, String
    rcvr :id_field,   String    
  end
  
  class CatalogTarget
    include Receiver
    rcvr :name,        String
    rcvr :title,       String
    rcvr :description, String
    rcvr :tags,        Array, :of => String
    rcvr :messages,    Array, :of => String
    rcvr :packages,    Array, :of => Hash
  end
end
