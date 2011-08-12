module Icss

  class IdenticalFactory
    def self.receive(obj)
      obj
    end
  end
  class HashlikeFactory < IdenticalFactory
  end
  class ArrayFactory < IdenticalFactory
  end

  module Meta
    module TypeFactory


      ::Icss::FACTORY_TYPES.merge!({
        Icss::Meta::TypeFactory => Icss::Meta::TypeFactory,
        Object => Icss::IdenticalFactory,
        Hash   => Icss::HashlikeFactory,
        Array  => Icss::ArrayFactory,
        Icss::IdenticalFactory => Icss::IdenticalFactory,
        Icss::HashlikeFactory  => Icss::HashlikeFactory,
        Icss::ArrayFactory     => Icss::ArrayFactory,
      })

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
        # ap [__FILE__, 'tf', flavor, schema, klass]
        case flavor
        when :primitive       then return klass
        when :simple          then return klass
        when :is_type         then return klass
        when :factory         then return klass
        when :complex_type    then
          ret = receive_complex_type(schema, klass)
          return ret
        when :record_type     then return receive_record_type(schema)
        when :union_type
          ap ["UNION TYPE", schema, flavor, klass, Icss::UNION_TYPES]
          return receive_union_type(schema)
        when :defined_type    then return receive_defined_type(klass)
        else
          raise ArgumentError, %Q{Can not create #{schema.inspect}: should be the handle for a named type; an array (representing a union type); one of #{SIMPLE_TYPES.keys.join(',')}; or a schema of the form {"type": "typename" ...attributes...}.}
        end
      end

      def self.classify_schema_declaration(schema)

        if schema.respond_to?(:each_pair)
          schema.symbolize_keys!
          type = schema[:type]
        else
          type = schema
        end
        type = type.to_sym if type.respond_to?(:to_sym)

        # pp [__FILE__, 'classify_schema_declaration', schema, type, ::Icss::COMPLEX_TYPES]

        if    schema.is_a?(Array)                   then return [:union_type, nil]
        elsif type.respond_to?(:each_pair)        then
          p ['recursing!', type, schema];
          return [:is_type, Icss::Meta::TypeFactory.receive(type)]
        elsif ::Icss::FACTORY_TYPES.include?(type)   then return [:factory,      FACTORY_TYPES[type]]
        elsif ::Icss::PRIMITIVE_TYPES.has_key?(type) then return [:primitive,    PRIMITIVE_TYPES[type]]
        elsif ::Icss::SIMPLE_TYPES.has_key?(type)    then return [:simple,       SIMPLE_TYPES[type]]
        elsif ::Icss::COMPLEX_TYPES.has_key?(type)   then return [:complex_type, COMPLEX_TYPES[type]]
        elsif ::Icss::RECORD_TYPES.has_key?(type)    then return [:record_type,  RECORD_TYPES[type]]
        elsif ::Icss::UNION_TYPES.has_key?(type)     then
          return [:union_type,   UNION_TYPES[type]]
        elsif type.is_a?(Module)                     then
          return [:is_type,      type]
        else
          return [:defined_type, type]
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

      def self.receive_complex_type(schema, schema_writer)
        klass = schema_writer.receive_schema(schema)
        klass
      end

    end
  end
end
