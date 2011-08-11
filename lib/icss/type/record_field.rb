module Icss
  module Meta

    class RecordField
      include Icss::Meta::RecordType
      remove_possible_method(:type)

      field :name,      Symbol,                  :required => true
      field :type,      Icss::Meta::TypeFactory, :required => true
      field :doc,       String
      field :default,   Object
      field :required,  Boolean
      field :order,     String
      field :validates, Hash
      attr_reader   :parent
      attr_accessor :is_reference

      # is the field a reference to a named type (true), or an inline schema (false)?
      def is_reference?() is_reference ; end

      ALLOWED_ORDERS = %w[ascending descending ignore].freeze unless defined?(ALLOWED_ORDERS)
      def order
        @order || 'ascending'
      end
      def order_direction
        case order when 'ascending' then 1 when 'descending' then -1 else 0 ; end
      end
    end


    module RecordType

      module Schema
        def receive_fields(fields)
          fields.each do |field_schema|
            field_schema.symbolize_keys!
            field(field_schema[:name], field_schema[:type], field_schema)
          end
        end

        class Writer < ::Icss::Meta::NamedSchema::Writer
          field :fields,           Array
          field :is_a,             :array, :items => Icss::Meta::TypeFactory
          field :_domain_id_field, Icss::Meta::TypeFactory

          def self.inscribe_schema(schema_obj, type_schema)
            type_schema.singleton_class.class_eval{ define_method(:_schema){ schema_obj } }
            field_names.each do |attr|
              val = schema_obj.send(attr)
              rcv_meth = "receive_#{attr}"
              if type_schema.respond_to?(rcv_meth)
                type_schema.send(rcv_meth, val)
              end
            end
          end

          def self.receive_schema(schema)
            schema_obj = self.receive(schema)
            schema_obj.fullname ||= get_klass_name(schema)
            ap [__FILE__, schema_obj.is_a, schema_obj, self.fields]
            superklass = schema_obj.is_a.first || Object
            warn "No multiple inheritance yet" if schema_obj.is_a.length > 1
            type_klass = Icss::Meta::NamedSchema.get_type_klass(schema_obj.fullname, superklass)
            type_klass.class_eval{ include(::Icss::Meta::RecordType) }
            #
            inscribe_schema(schema_obj, type_klass)
            type_klass.metatype
            type_klass
          end
        end

      end
    end

  end
end
