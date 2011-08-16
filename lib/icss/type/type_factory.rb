module Icss
  module Meta

    # Receives any object just as given.
    #
    # @example
    #   # receive_foo accepts the item just as given
    #   field :foo, Icss::Meta::IdenticalFactory
    #
    class IdenticalFactory
      def self.receive(obj)
        obj
      end
    end

    module TypeFactory

      ::Icss::FACTORY_TYPES.merge!({
          Icss::Meta::TypeFactory       => Icss::Meta::TypeFactory,
          Object                        => Icss::Meta::IdenticalFactory,
          Icss::Meta::IdenticalFactory  => Icss::Meta::IdenticalFactory,
        })

      #
      # A Schema is represented by one of:
      #
      # * A symbol or string, naming a defined type.
      # * A class that responds to +.receive+, returned as itself
      # * A hash (respond_to?(:each_pair), of the form:
      #       {"type": "typeName" ...attributes...}
      #   where typeName is either a simple or derived type name, as defined
      #   in the Icss::Type class
      # * An array, representing a union of embedded types.
      #
      def self.receive schema
        flavor, klass = classify_schema_declaration(schema)
        p [__FILE__, 'tf', schema, flavor, klass]
        case flavor
        when :simple            then return klass
        when :factory           then return klass
        when :is_type           then return klass
        when :structured_schema then return receive_structured_schema(klass, schema)
        when :union_schema      then return receive_union_schema(klass, schema)
        when :named_type        then return receive_named_type(klass, schema)
        else
        end
      end

      #
      # A Schema is represented by one of:
      #
      # * A symbol or string, naming a defined type.
      # * A class that responds to +.receive+, returned as itself
      # * A hash (respond_to?(:each_pair), of the form:
      #       {"type": "typeName" ...attributes...}
      #   where typeName is either a simple or derived type name, as defined
      #   in the Icss::Type class
      # * An array, representing a union of embedded types.
      #
      #
      def self.classify_schema_declaration(schema)
        type = (schema.respond_to?(:each_pair) ? schema[:type] : schema)
        type = type.to_sym if type.respond_to?(:to_sym)
        if    ::Icss::SIMPLE_TYPES.include?(type)             then return [:simple,            SIMPLE_TYPES[type]]
        elsif ::Icss::FACTORY_TYPES.include?(type)            then return [:factory,           FACTORY_TYPES[type]]
        elsif ::Icss::STRUCTURED_SCHEMAS.include?(type)       then return [:structured_schema, STRUCTURED_SCHEMAS[type]]
        elsif (type == :union) || type.is_a?(Array)           then return [:union_schema,      Icss::Meta::UnionSchema::Writer]
        elsif type.is_a?(Module)                              then return [:is_type,           type]
        elsif type.is_a?(Symbol) && type.to_s =~ /^[\w\.\:]+/ then return [:named_type,        type]
        else  raise ArgumentError, %Q{Can not classify #{schema.inspect}: should be the handle for a named type; one of #{SIMPLE_TYPES.keys.join(',')}; a schema of the form {"type": "typename" ...attributes....}; or an array (representing a union type).}
        end
      end

   protected

      def self.receive_named_type(type, schema)
        Icss::Meta::Type.klassname_for(type.to_sym).constantize
      end

      def self.receive_structured_schema(schema_writer, schema)
        schema_writer.receive_schema(schema)
      end

      def self.receive_union_schema(schema_writer, schema)
        schema_writer.receive_schema(schema)
      end

    end
  end
end
