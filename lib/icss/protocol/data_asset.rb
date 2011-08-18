module Icss
  module Meta
    class DataAsset
      include Icss::ReceiverModel

      field :name,      String
      field :location,  String
      # overriding ruby's deprecated but still present type attr on objects
      attr_accessor :type
      field :type,      String
      field :doc,       String

      def named? nm
        name == nm
      end

      def to_hash()
        { :name => name, :location => location, :type => type, :doc => doc }
      end
      def to_json() to_hash.to_json ; end
    end
  end
end
