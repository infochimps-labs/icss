module Icss
  module Type

    # module ErrorType
    #   include RecordType
    # end

    #
    # Describes an Avro Enum type.
    #
    # Enums use the type name "enum" and support the following attributes:
    #
    # name:       a string providing the name of the enum (required).
    # namespace:  a string that qualifies the name;
    # doc:        a string providing documentation to the user of this schema (optional).
    # symbols:    an array, listing symbols, as strings or ruby symbols (required). All
    #             symbols in an enum must be unique; duplicates are prohibited.
    #
    # For example, playing card suits might be defined with:
    #
    # { "type": "enum",
    #   "name": "Suit",
    #   "symbols" : ["SPADES", "HEARTS", "DIAMONDS", "CLUBS"]
    # }
    #
    module EnumType
      extend NamedType
      field :symbols, Array, :of => String, :required => true
      def schema_hash
        super.merge( :symbols => symbols )
      end
    end

    #
    # base class for Avro enumerable types (array, map and union)
    #
    # (do not confuse with EnumType, which is not an EnumerableType. sigh).
    #
    class EnumerableType < Type
      class_attribute :type
      class_attribute :ruby_klass

      def schema_hash
        super.merge( :type => type.to_s )
      end
    end

    #
    # ArrayType describes an Avro Array type.
    #
    # Arrays use the type name "array" and support a single attribute:
    #
    # * items: the schema of the array's items.
    #
    # @example, an array of strings is declared with:
    #
    #     {"type": "array", "items": "string"}
    #
    class ArrayType < EnumerableType
      rcvr_accessor :items, TypeFactory, :required => true
      self.type = :array
      self.ruby_klass = Array

      def title
        "array of #{items.title}"
      end

      def schema_hash
        super.merge( :items => (items && items.name) )
      end
    end

    #
    # MapType describes an Avro Map type (which corresponds to a Ruby
    # Hash). HashType is a synonym for MapType.
    #
    # Maps use the type name "map" and support one attribute:
    #
    # * values: the schema of the map's values. Avro Map keys are assumed to be strings.
    #
    # @example, a map from string to long is declared with:
    #
    #     {"type": "map", "values": "long"}
    #
    class MapType < EnumerableType
      rcvr_accessor :values, TypeFactory, :required => true
      self.type       = :map
      self.ruby_klass = Hash
      def schema_hash
        super.merge( :values => values.to_hash )
      end
    end

    HashType = MapType unless defined?(HashType)

    #
    # Describes an Avro Union type.
    #
    # Unions are represented using JSON arrays. For example, ["string", "null"]
    # declares a schema which may be either a string or null.
    #
    # Unions may not contain more than one schema with the same type, except for
    # the named types record, fixed and enum. For example, unions containing two
    # array types or two map types are not permitted, but two types with different
    # names are permitted. (Names permit efficient resolution when reading and
    # writing unions.)
    #
    # Unions may not immediately contain other unions.
    #
    class UnionType < EnumerableType
      attr_accessor :available_types
      attr_accessor :referenced_types
      self.type = :union
      def receive! type_list
        self.available_types = type_list.map do |type_info|
          type = TypeFactory.receive(type_info)
          (referenced_types||=[]) << type if (type_info.is_a?(String) || type_info.is_a?(Symbol))
          type
        end
      end
      def schema_hash
        available_types.map{|t| t.name } #  (referenced_types||=[]).include?(t) ? t.name : t.schema_hash }
      end
    end

    #
    # Describes an Avro Fixed type.
    #
    # Fixed uses the type name "fixed" and supports the attributes:
    #
    # * name: a string naming this fixed (required).
    # * namespace, a string that qualifies the name;
    # * size: an integer, specifying the number of bytes per value (required).
    #
    #   For example, 16-byte quantity may be declared with:
    #
    #     {"type": "fixed", "size": 16, "name": "md5"}
    #
    class FixedType < NamedType
      rcvr_accessor :size, Integer, :required => true
      class_attribute :ruby_klass
      self.type = :fixed
      self.ruby_klass = String
      def schema_hash
        super.merge( :size => size )
      end
    end


    unless defined?(ENUMERABLE_TYPES)
      Icss::Type::ENUMERABLE_TYPES = {
        :hash    => Icss::Type::MapType,
        :map     => Icss::Type::MapType,
        :array   => Icss::Type::ArrayType,
        :union   => Icss::Type::UnionType,
      }.freeze
    end

    unless defined?(NAMED_TYPES)
      Icss::Type::NAMED_TYPES      = {
        :fixed   => Icss::Type::FixedType,
        :enum    => Icss::Type::EnumType,
        :record  => Icss::Type::RecordType,
        :error   => Icss::Type::ErrorType
      }.freeze
    end

  end
end
