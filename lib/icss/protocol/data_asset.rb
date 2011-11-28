module Icss
  module Meta
    class DataAsset
      include Icss::ReceiverModel

      field :name,           String
      field :location,       String
      # overriding ruby's deprecated but still present type attr on objects
      attr_accessor :type
      field :type,           String
      field :doc,            String
      
      field :asset_type,     String
      field :filetype,       String
      field :md5,            String
      field :size,           String
      field :extracted_size, String

      def named? nm
        name == nm
      end

      def to_hash()
        { :name => name, :location => location, :type => type, :doc => doc, :asset_type => asset_type, :filetype => filetype, :md5 => md5, :size => size, :extracted_size => extracted_size }
      end
      def to_json() to_hash.to_json ; end
    end
  end
end
