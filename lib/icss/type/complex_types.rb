module Icss

  #
  # Icss/Avro Record type
  #
  # Records use the type name "record" and support these attributes:
  #
  # * name:      a string providing the name of the record (required).
  # * namespace: a string that qualifies the name;
  # * doc:       a string providing documentation to the user of this schema (optional).
  # * fields:    an array of RecordField's (required).
  #
  # For example, a linked-list of 64-bit values may be defined with:
  #
  #         {
  #           "type": "record",
  #           "name": "LongList",
  #           "fields" : [
  #             {"name": "value", "type": "long"},             // each element has a long
  #             {"name": "next", "type": ["LongList", "null"]} // optional next element
  #           ]
  #         }
  #
  class RecordType < NamedType

    rcvr_accessor :fields, Array, :of => Icss::RecordField, :required => true
    rcvr_accessor :is_a, Array, :of => String, :default => []
    self.type = :record

    after_receive do |hsh|
      is_a.each do |ref|
        addon = ReferencedType.receive(ref)
        fields.push(addon.fields).flatten!
      end
      Icss::Type::DERIVED_TYPES[name.to_sym] = self
    end

    def to_hash
      super.merge( :fields => ( fields || [] ).map{ |field| field.to_hash } )
    end

  end

  class ReferencedType < RecordType
    def self.receive(ref_type)
      split_name = ref_type.to_s.split('.')
      name = split_name.pop
      nmsp = split_name.join('_')
      super(lookup_ref(nmsp, name))
    end

    def self.lookup_ref(nmsp, name)
      ref = YAML.load(File.read(File.join(File.dirname(__FILE__), nmsp) + '.yaml'))
      ref['types'].select{ |t| t['name'] == name }.first
    end
  end

  class ErrorType < RecordType
    self.type = :error
  end

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
  class EnumType < NamedType
    rcvr_accessor :symbols, Array, :of => String, :required => true
    self.type = :enum

    def to_hash
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

    def to_hash
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

    def to_hash
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
    def to_hash
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
    def to_hash
      available_types.map{|t| t.name } #  (referenced_types||=[]).include?(t) ? t.name : t.to_hash }
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
    def to_hash
      super.merge( :size => size )
    end
  end

end
