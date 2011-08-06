module Icss
  module Type
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
        case classify_schema_declaration(schema)
        when :is_type    then return schema
        when :union_type then return receive_union_type(schema)
        when :schema     then return receive_complex_type(schema)
        when :primitive  then return Icss::Type::PRIMITIVE_TYPES[schema.to_sym]
        when :simple     then return Icss::Type::SIMPLE_TYPES[schema.to_sym]
        when :named_type then return receive_named_type(schema)
        else
          raise %Q{Type must be either: the handle for a named type; an array (representing a union type); one of #{Icss::Type::TYPE_ALIASES.join(',')}; or a hash of the form {"type": "type_name" ...attributes...}.}
        end
      end

      def self.classify_schema_declaration(schema)
        if    schema.is_a?(Class)                   then return :is_type
        elsif schema.is_a?(Array)                   then return :union_type
        elsif schema.respond_to?(:each_pair)        then return :schema
        elsif schema.respond_to?(:to_sym)
          type_name = schema.to_sym
          if    PRIMITIVE_TYPES.has_key?(type_name) then return :primitive
          elsif SIMPLE_TYPES.has_key?(type_name)    then return :simple
          else                                           return :named_type ; end
        else
            return nil
        end
      end

    protected

      def self.receive_named_type(schema)
        Icss::Type::NamedType.klassname_for(schema.to_sym).constantize
      end

      def self.receive_union_type(schema)
        Icss::Type::UnionType.receive(schema)
      end

      def self.receive_complex_type(schema)
        schema = schema.symbolize_keys
        raise "No type was given in #{schema.inspect}" if schema[:type].blank?
        type_name = schema[:type].to_sym
        type = Icss::Type.find(type_name)
        obj = type.receive(schema)
      end

      # def decorate_with_validators klass
      #   fields.each do |field|
      #     puts field.to_hash
      #     if field.validates
      #       puts field.validates
      #       klass.validates(field.name.to_sym, field.validates)
      #     end
      #   end
      # end

    end
  end
end
