module Icss
  module Meta
    class License
      include Icss::ReceiverModel
      include Icss::ReceiverModel::ActsAsCatalog

      field :license_id,      String
      field :title,           String
      field :url,             String
      field :description,     String
      field :summary,         String
      field :article_body,    String
      
      def fullname
        license_id
      end
      
      def name
        license_id.split('.').last
      end
      alias_method :basename, :name

      def self.catalog_sections
        ['licenses', 'legacy/licenses']
      end

      def to_hash()
        { :license_id => license_id,
          :title => title,
          :url => url,
          :description => description,
          :summary => summary,
          :article_body => article_body }
      end

      def to_json() to_hash.to_json ; end

    end
  end

end
