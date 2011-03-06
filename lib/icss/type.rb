module Icss
  #
  # Describes an avro type
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
  class Type
    include Receiver
    rcvr_accessor :name,       String
    rcvr_accessor :doc,        String
    # Schema factory
    rcvr_accessor :ruby_klass, Object
    rcvr_accessor :pig_name,   String

    #
    # Factory methods
    #

    # Registry for synthesized types (eg the result of a type record definition)
    Icss::Type::DERIVED_TYPES = {}   unless defined?(Icss::Type::DERIVED_TYPES)

    # VALID_TYPES, PRIMITIVE_TYPES, etc are way down below (the klasses need to
    # be defined first)

    #
    def self.find type_name
      if type_name.to_s.include?('.')
        warn "crap. can't properly do namespaced types yet."
        type_name = type_name.to_s.gsub(/(.*)\./, "")
      end
      VALID_TYPES[type_name.to_sym] || DERIVED_TYPES[type_name.to_sym]
    end

    def self.primitive? name
      PRIMITIVE_TYPES.include?(name.to_sym)
    end

    #
    # Schema Translation
    #

    def pig_name
      self.class.pig_name
    end

    #
    # Conversion
    #

    def to_hash()
      {:name => name, :doc => doc }.reject{|k,v| v.nil? }
    end
    # This will cause funny errors when it is an element of something that's to_json'ed
    def to_json() to_hash.to_json ; end
  end

  # ---------------------------------------------------------------------------
  #
  # Primitive Types
  #

  class PrimitiveType < Type
    def to_hash
      name.to_s
    end
  end

  # Registry for primitive types
  unless defined?(::Icss::Type::PRIMITIVE_TYPES)
    ::Icss::Type::PRIMITIVE_TYPES = {}
    ::Icss::Type::PRIMITIVE_TYPES[:null]    = PrimitiveType.new(:ruby_klass => NilClass, :pig_name => 'FIXME WHAT GOES HERE' )
    ::Icss::Type::PRIMITIVE_TYPES[:boolean] = PrimitiveType.new(:ruby_klass => Boolean,  :pig_name => 'FIXME WHAT GOES HERE')
    ::Icss::Type::PRIMITIVE_TYPES[:string]  = PrimitiveType.new(:ruby_klass => Integer,  :pig_name => 'int')
    ::Icss::Type::PRIMITIVE_TYPES[:bytes]   = PrimitiveType.new(:ruby_klass => Integer,  :pig_name => 'long')
    ::Icss::Type::PRIMITIVE_TYPES[:int]     = PrimitiveType.new(:ruby_klass => Float,    :pig_name => 'float')
    ::Icss::Type::PRIMITIVE_TYPES[:long]    = PrimitiveType.new(:ruby_klass => Float,    :pig_name => 'double')
    ::Icss::Type::PRIMITIVE_TYPES[:float]   = PrimitiveType.new(:ruby_klass => String,   :pig_name => 'bytearray')
    ::Icss::Type::PRIMITIVE_TYPES[:double]  = PrimitiveType.new(:ruby_klass => String,   :pig_name => 'chararray')
    ::Icss::Type::PRIMITIVE_TYPES.freeze
  end

  # ---------------------------------------------------------------------------
  #
  # Complex Types
  #

  #
  # Record, enums and fixed are named types. Each has a fullname that is
  # composed of two parts; a name and a namespace. Equality of names is defined
  # on the fullname.
  #
  # The name portion of a fullname, and record field names must:
  # * start with [A-Za-z_]
  # * subsequently contain only [A-Za-z0-9_]
  # * A namespace is a dot-separated sequence of such names.
  #
  # References to previously defined names are as in the latter two cases above:
  # if they contain a dot they are a fullname, if they do not contain a dot, the
  # namespace is the namespace of the enclosing definition.
  #
  # Primitive type names have no namespace and their names may not be defined in
  # any namespace. A schema may only contain multiple definitions of a fullname
  # if the definitions are equivalent.
  #
  #
  class NamedType < Type
    rcvr_accessor :namespace, String
    attr_accessor :parent
    # the avro base type name
    class_inheritable_accessor :type
    include Icss::Validations

    # In named types, the namespace and name are determined in one of the following ways:
    #
    # * A name and namespace are both specified. For example, one might use
    #   "name": "X", "namespace": "org.foo" to indicate the fullname org.foo.X.
    #
    # * A fullname is specified. If the name specified contains a dot, then it is
    #   assumed to be a fullname, and any namespace also specified is ignored. For
    #   example, use "name": "org.foo.X" to indicate the fullname org.foo.X.
    #
    # * A name only is specified, i.e., a name that contains no dots. In this case
    #   the namespace is taken from the most tightly enclosing schema or
    #   protocol. For example, if "name": "X" is specified, and this occurs within
    #   a field of the record definition of org.foo.Y, then the fullname is
    #   org.foo.X.
    #
    def name= nm
      if nm.include?('.')
        split_name = nm.split('.')
        @use_fullname = true
        @name      = split_name.pop
        @namespace = split_name.join('.')
      else
        @name = nm
      end
      ::Icss::Type::DERIVED_TYPES[@name.to_sym] = self
      @name
    end

    def receive_namespace nmsp
      # If the namespace is given in the name (using a dotted name string) then
      # any namespace also specified is ignored.
      if @namespace then warn "Warning: namespace already set, ignoring" and return ; end
      @namespace = nmsp
    end

    def namespace
      @namespace || parent.namespace
    end

    #
    # If no explicit namespace is specified, the namespace is taken from the
    # most tightly enclosing schema or protocol. For example, if "name": "X" is
    # specified, and this occurs within a field of the record definition of
    # org.foo.Y, then the fullname is org.foo.X.
    #
    def fullname
      [namespace, name].join('.')
    end

    def to_hash
      hsh = super
      if    @use_fullname then hsh[:name] = fullname
      elsif @namespace    then hsh.merge!( :namespace => @namespace ) ; end
      hsh.merge( :type => self.class.type )
    end
  end

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
  class TypeFactory
    def self.receive type_info
      # p ['----------', self, 'receive', type_info] # , Icss::Type::DERIVED_TYPES]
      case
      when type_info.is_a?(String) || type_info.is_a?(Symbol)
        Icss::Type.find(type_info)
      when type_info.is_a?(Array)
        UnionType.receive(type_info)
      else
        type_info  = type_info.symbolize_keys
        type_name = type_info[:type].to_sym
        type = Icss::Type.find(type_name)
        obj  = type.receive(type_info)
      end
    end
  end

  #
  # Describes a field in an Avro Record object.
  #
  # Each field has the following attributes:
  # * name:     a string providing the name of the field (required), and
  # * doc:      a string describing this field for users (optional).
  # * type:     a schema, or a string or symbol naming a record definition (required).
  #
  #             avro type     json type       ruby type       example
  #             null          null            NilClass        nil
  #             boolean       boolean         Boolean         true
  #             int,long      integer         Integer         1
  #             float,double  number          Float           1.1
  #             bytes         string          String          "\u00FF"
  #             string        string          String          "foo"
  #             record        object          RecordType      {"a": 1}
  #             enum          string          Enum            "FOO"
  #             array         array           Array           [1]
  #             map           object          Hash            { "a": 1 }
  #             fixed         string          String          "\u00ff"
  #
  # * default:  a default value for this field, used when reading instances that
  #             lack this field (optional). Permitted values depend on the
  #             field's schema type, according to the table below. Default
  #             values for union fields correspond to the first schema in the
  #             union. Default values for bytes and fixed fields are JSON
  #             strings, where Unicode code points 0-255 are mapped to unsigned
  #             8-bit byte values 0-255.
  #
  # * order:    specifies how this field impacts sort ordering of this record
  #             (optional). Valid values are "ascending" (the default),
  #             "descending", or "ignore". For more details on how this is used,
  #             see the the sort order section below.
  #
  # See RecordType for examples.
  #
  class RecordField
    include Receiver
    rcvr_accessor :name,      String, :required => true
    rcvr_accessor :doc,       String
    rcvr_accessor :type,      Icss::Type, :required => true
    rcvr_accessor :default,   Object # accept and love the object just as it is
    rcvr          :order,     String
    # is_reference is true if the type is a named reference to a defined type;
    # false if the type was defined right here in the schema.
    attr_accessor :is_reference
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

    def to_hash()
      { :name    => name,
        :type    => (is_reference? ? (type ? type.name : "why null") : type.to_hash),
        :default => default,
        :order   => @order,
        :doc     => doc,
      }.reject{|k,v| v.nil? }
    end
  end

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
    self.type = :record

    # def ruby_klass
    #   @klass ||= Class.new do
    #     fields.each do |field|
    #       instance_eval{ field.define_receiver }
    #     end
    #   end
    # end

    def to_hash
      super.merge( :fields => (fields||[]).map{|field| field.to_hash} )
    end
  end

  #  An error definition is just like a record definition except it uses "error" instead of "record".
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
    rcvr_accessor :symbols, Array, :of => Symbol, :required => true
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
    class_inheritable_accessor :type
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
    # FIXME: is items required? The schema doesn't say so.
    rcvr_accessor :items, TypeFactory
    self.type = :array

    def to_hash
      super.merge( :items => items.name )
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
    # FIXME: is items required? The schema doesn't say so.
    rcvr_accessor :values, TypeFactory
    self.type = :map

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
    self.type = :fixed

    def to_hash
      super.merge( :size => size )
    end
  end

  Type.class_eval do
    Icss::Type::NAMED_TYPES      = {
      :fixed   => FixedType,
      :enum    => EnumType,
      :record  => RecordType,
      :error   => ErrorType
    }.freeze unless defined?(Icss::Type::NAMED_TYPES)
    Icss::Type::ENUMERABLE_TYPES = {
      :array   => ArrayType,
      :map     => MapType,
      :union   => UnionType,
      # :request => RequestType,
    }.freeze unless defined?(Icss::Type::ENUMERABLE_TYPES)
    Icss::Type::VALID_TYPES  = (Icss::Type::PRIMITIVE_TYPES.merge(Icss::Type::NAMED_TYPES.merge(Icss::Type::ENUMERABLE_TYPES))).freeze unless defined?(Icss::Type::VALID_TYPES)
    Icss::Type::VALID_TYPES.each{|n, t| t.name = n if t.is_a?(Icss::Type) }
  end
end
