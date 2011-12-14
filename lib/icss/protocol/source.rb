module Icss
  module Meta
    class Source
      include Icss::ReceiverModel
      include Icss::ReceiverModel::ActsAsCatalog
      
      field :source_id,   String
      field :title,       String
      field :description, String
      field :url,         String
      
      def fullname
        source_id
      end
      
      def name
        source_id.split('.').last
      end
      alias_method :basename, :name

      def self.catalog_sections
        ['sources', 'legacy/sources']
      end

      def to_hash()
        { :source_id => source_id,
          :title => title,
          :description => description,
          :url => url }
      end

      def to_json() to_hash.to_json ; end

    end
  end

end
