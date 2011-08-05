module Icss
  module Type
    class RecordField
      include Icss::Type::RecordType
      remove_possible_method(:type)

      field :name,      String, :required => true
      field :doc,       String
      field :type,      String, :required => true
      field :default,   Object
      field :required,  Boolean
      field :order,     String
      field :validates, Hash
      attr_reader   :parent
      attr_accessor :is_reference

      def receive_type type_info
        self.type = TypeFactory.receive(type_info)
      end

      # is the field a reference to a named type defined elsewhere, or is it an
      # inline schema?
      def is_reference?() is_reference ; end

      ALLOWED_ORDERS = %w[ascending descending ignore].freeze unless defined?(ALLOWED_ORDERS)
      def order
        @order || 'ascending'
      end
      def order_direction
        case order when 'ascending' then 1 when 'descending' then -1 else 0 ; end
      end

      def record?() type.is_a? Icss::RecordType end
      def union?()  type.is_a? Array            end
      def enum?()   type.is_a? Icss::EnumType   end

      def to_hash()
        { :name    => name,
          :type    => expand_type,
          :default => default,
          :order   => @order,
          :doc     => doc,
        }.reject{|k,v| v.nil? }
      end

      def expand_type
        case
        when is_reference? && type.respond_to?(:name) then type.name
        when is_reference?                            then '(_unspecified_)'
        when type.is_a?(Array)          then type.map{|t| t.to_hash }
        when type.respond_to?(:to_hash) then type.to_hash
        else type.to_s
        end
      end
    end
  end
end
