module Icss

  #
  # Instantiates an array of target objects
  #
  class TargetListFactory
    def self.receive target_info_list, target_name
      klass = "Icss::#{target_name.camelize}Target".constantize
      target_info_list.map{|target_info| klass.receive(target_info)}
    end
  end

  class Target
    include Icss::ReceiverModel
    field :name, String
    alias_method :basename, :name
  end

  class MysqlTarget < Target
    field :data_assets,     Array, :items => String
    field :database,        String
    field :table_name,      String
  end

  class ApeyeyeTarget < Target
    field :code_assets,     Array, :items => String
  end

  class HbaseTarget < Target
    field :data_assets,     Array, :items => String
    field :table_name,      String
    field :column_families, Array, :items => String
    field :column_family,   String
    field :loader,          String
    field :id_field,        String
  end

  class ElasticSearchTarget < Target
    field :data_assets,     Array, :items => String
    field :index_name,      String
    field :id_field,        String
    field :object_type,     String
    field :loader,          String
  end

  class GeoIndexTarget < Target
    field :data_assets,     Array, :items => String
    field :table_name,      String
    field :min_zoom,        Integer
    field :max_zoom,        Integer
    field :chars_per_page,  Integer
    field :sort_field,      String
  end

  class CatalogTarget < Target
    field :name,            String
    field :license,         String
    field :title,           String
    field :link,            String
    field :description,     String
    field :owner,           String
    field :price,           Float
    field :tags,            Array, :items => String
    field :messages,        Array, :items => String
    field :packages,        Array, :items => { :type => Hash, :values => Object }
  end

end
