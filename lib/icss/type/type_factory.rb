module Icss

  class Dummy
    def self.receive(obj)
      obj
    end
  end

  module Meta
    module TypeFactory

      #
      # Avro Schema Declaration
      #
      # A Schema is represented in JSON by one of:
      #
      # * A JSON string, naming a defined type.
      # * A JSON object, of the form:
      #       {"type": "typeName" ...attributes...}
      #   where typeName is either a primitive or derived type name, as defined
      #   in the Icss::Type class
      # * A JSON array, representing a union of embedded types.
      #
      #
      def self.receive schema
        flavor, klass = classify_schema_declaration(schema)
        case flavor
        when :dummy        then return schema
        when :is_type         then return schema
        when :union_type      then return receive_union_type(schema)
        when :container_type  then return receive_complex_type(schema, klass)
        when :named_type      then return receive_complex_type(schema, klass)
        when :primitive       then return klass
        when :simple          then return klass
        when :defined_type    then return receive_defined_type(schema)
        else
          raise ArgumentError, %Q{Can not create #{schema.inspect}: should be the handle for a named type; an array (representing a union type); one of #{SIMPLE_TYPES.keys.join(',')}; or a schema of the form {"type": "typename" ...attributes...}.}
        end
      end

      def self.classify_schema_declaration(schema)
        if    [Object,Icss::Dummy].include?(schema) then return [:dummy,   Icss::Dummy]
        elsif schema.is_a?(Class)                   then return [:is_type,    schema]
        elsif schema.is_a?(Array)                   then return [:union_type, nil]
        elsif schema.respond_to?(:each_pair)
          schema.symbolize_keys!
          typename = schema[:type].to_sym
          if    CONTAINER_TYPES.has_key?(typename)  then return [:container_type, CONTAINER_TYPES[typename]]
          elsif NAMED_TYPES.has_key?(typename)      then return [:named_type,     NAMED_TYPES[typename]]
          else raise
          end
        elsif schema.respond_to?(:to_sym)
          typename = schema.to_sym
          if    PRIMITIVE_TYPES.has_key?(typename) then return [:primitive,    PRIMITIVE_TYPES[typename]]
          elsif SIMPLE_TYPES.has_key?(typename)    then return [:simple,       SIMPLE_TYPES[typename]]
          else                                          return [:defined_type, typename] ; end
        else
            return nil
        end
      end

    protected

      def self.find_in_type_collection(type_collection, kind, typename)
        type_collection[typename.to_sym] or raise(ArgumentError, "No such #{kind} type #{typename}")
      end

      def self.receive_defined_type(schema)
        Icss::Meta::Type.klassname_for(schema.to_sym).constantize
      end

      def self.receive_union_type(schema)
        Icss::Meta::UnionType.receive(schema)
      end

      def self.receive_complex_type(schema, klass)
        schema.symbolize_keys!
        obj = klass.receive(schema)
      end

    end
  end
end
