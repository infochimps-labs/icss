module Icss
  module Meta



    class RecordField
      include Receiver
      include Receiver::ActsAsHash
      include Receiver::ActiveModelShim

      rcvr_accessor :name,      String, :required => true
      rcvr_accessor :doc,       String
      attr_accessor :type # work around a bug in ruby 1.8, which has defined (and deprecated) type
      rcvr_accessor :type,      String, :required => true

      rcvr_accessor :default,   Object
      rcvr          :order,     String
      rcvr_accessor :required,  Boolean

      rcvr_accessor :validates, Hash

      attr_accessor :is_reference

      def type
        return @type if @type.is_a?(Icss::Type)
        @type = Icss::Type::DERIVED_TYPES[@type.to_sym]
        @type
      end

      def is_reference?() is_reference ; end

      def receive_type type_info
        self.is_reference = type_info.is_a?(String) || type_info.is_a?(Symbol)
        self.type = TypeFactory.receive(type_info)
      end

      ALLOWED_ORDERS = %w[ascending descending ignore].freeze unless defined?(ALLOWED_ORDERS)
      def order
        @order || 'ascending'
      end
      def order_direction
        case order when 'ascending' then 1 when 'descending' then -1 else 0 ; end
      end
      # QUESTION: should this be an override of order=, or of receive_order?
      def order= v
        raise "'order' may only take the values ascending (the default), descending, or ignore." unless v.nil? || ALLOWED_ORDERS.include?(v)
        @order = v
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
