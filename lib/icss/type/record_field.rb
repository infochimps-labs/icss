module Icss
  module Meta
    class RecordField
      include Icss::Meta::RecordType
      remove_possible_method(:type)

      field :name,      Symbol,                  :required => true
      field :type,      Icss::Meta::TypeFactory, :required => true
      field :doc,       String
      field :default,   Object
      field :required,  BooleanType
      field :order,     String
      field :validates, Hash
      attr_reader   :parent
      attr_accessor :is_reference

      def receive_type(schema)
        self.type = schema
      end

      # is the field a reference to a named type (true), or an inline schema (false)?
      def is_reference?() is_reference ; end

      ALLOWED_ORDERS = %w[ascending descending ignore].freeze unless defined?(ALLOWED_ORDERS)
      def order
        @order || 'ascending'
      end
      def order_direction
        case order when 'ascending' then 1 when 'descending' then -1 else 0 ; end
      end

      # def record?() type.is_a? Icss::Meta::RecordType end
      # def union?()  type.is_a? Icss::UnionType  end
      # def enum?()   type.is_a? Icss::EnumType   end

      def as_json()
        { :name     => name,
          :type     => expand_type,
          :doc      => doc,
          :default  => default,
          :required => required,
          :order    => @order,
        }.reject{|k,v| v.nil? }
      end

    protected
      def expand_type
        case
        when is_reference? && type.respond_to?(:fullname) then type.fullname
        when is_reference?                            then '(_unspecified_)'
        when type.is_a?(Array)                        then type.map{|t| t.to_hash }
        when type.respond_to?(:to_hash)               then type.to_hash
        else type.to_s
        end
      end
    end

    module RecordType
      module FieldDecorators
        # protected
        # def add_field_info(name, type, info_hsh)
        #   @field_names ||= [] ; @fields ||= {}
        #   @field_names << name unless respond_to?(:field_names) && field_names.include?(name)
        #   field_info = RecordField.receive(info_hsh.merge({ :name => name, :type => type }))
        #   @fields[name] = field_info
        # end
      end
    end
  end
end
