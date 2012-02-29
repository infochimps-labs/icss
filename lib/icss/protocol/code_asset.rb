module Icss
  module Meta
    class CodeAsset
      include Icss::ReceiverModel

      field :name,      String
      field :location,  String

      def to_hash()
        { :name => name, :location => location}
      end

      def to_json() to_hash.to_json ; end

    end
  end

end
