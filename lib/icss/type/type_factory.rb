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
      def self.receive type_info
        if    type_info.is_a?(Class)
          return type_info
        elsif type_info.is_a?(Array)
          return receive_union_type(type_info)
        elsif type_info.respond_to?(:each_pair)
          return receive_complex_type(type_info)
        elsif type_info.respond_to?(:to_sym)
          return receive_named_type(type_info)
        else
          raise %Q{Type must be either: the handle for a named type; an array (representing a union type); one of #{Icss::Type::TYPE_ALIASES.join(',')}; or a hash of the form {"type": "type_name" ...attributes...}.}
        end
      end

      def self.receive_named_type(type_info)
        type_info = type_info.to_sym
        if   Icss::Type::PRIMITIVE_TYPES.has_key?(type_info)
          return Icss::Type::PRIMITIVE_TYPES[type_info]
        elsif Icss::Type::SIMPLE_TYPES.has_key?(type_info)
          return Icss::Type::SIMPLE_TYPES[type_info]
        else
          type_name = Icss::Type::NamedType.klassname_for(type_info)
          return type_name.constantize
        end
      end

      def self.receive_union_type(type_info)
        UnionType.receive(type_info)
      end

      def self.receive_complex_type(type_info)
        type_info = type_info.symbolize_keys
        raise "No type was given in #{type_info.inspect}" if type_info[:type].blank?
        type_name = type_info[:type].to_sym
        type = Icss::Type.find(type_name)
        obj = type.receive(type_info)
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
