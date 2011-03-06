module Icss
  #
  # Generic ICSS base type
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
  # Here's the main thing you got to understand:
  #
  # * when I hit something under types: I define a class
  # * when I hit something under fields: I instantiate a class.
  #
  #

  class Type
    include Receiver
    rcvr_accessor :name,    String, :required => true, :validates => :validate_avro_name
    rcvr_accessor :doc,     String
    # Schema factory
    class_inheritable_accessor :ruby_klass, :pig_name

    #
    # Factory methods
    #

    # Registry for synthesized types (eg the result of a type record definition)
    Icss::Type::DERIVED_TYPES = {} unless defined?(Icss::Type::DERIVED_TYPES)

    # VALID_TYPES, PRIMITIVE_TYPES, etc are way down below (the klasses need to
    # be defined first)

    #
    def self.find type_name
      VALID_TYPES[type_name.to_sym] || DERIVED_TYPES[type_name.to_sym]
    end

    def self.primitive? name
      PRIMITIVE_TYPES.include?(name.to_sym)
    end

    #
    # Schema Translation
    #

    def pig_type
      self.class.pig_name
    end

    #
    # Conversion
    #

    def to_hash()
      {:name => name, :type => type, :doc => doc }
    end
    # This will cause funny errors when it is an element of something that's to_json'ed
    def to_json() to_hash.to_json ; end

  end

  # ---------------------------------------------------------------------------
  #
  # Primitive Types
  #

  class NilClassType < Type
    self.ruby_klass = NilClass
    self.pig_name  = 'FIXME WHAT GOES HERE' # FIXME: ??
  end
  class BooleanType < Type
    self.ruby_klass = Boolean
    self.pig_name  = 'FIXME WHAT GOES HERE' # FIXME: ??
  end
  class IntegerType < Type
    self.ruby_klass = Integer
    self.pig_name  = 'int'
  end
  class LongType < Type
    self.ruby_klass = Integer
    self.pig_name  = 'long'
  end
  class FloatType < Type
    self.ruby_klass = Float
    self.pig_name  = 'float'
  end
  class DoubleType < Type
    self.ruby_klass = Float
    self.pig_name  = 'double'
  end
  class BytesType < Type
    self.ruby_klass = String
    self.pig_name  = 'bytearray'
  end
  class StringType < Type
    self.ruby_klass = String
    self.pig_name  = 'chararray'
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

    # def initialize name
    #   ::Icss::Type::DERIVED_TYPES[name.to_sym] = self
    # end

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
        @name      = split_name.pop
        @namespace = split_name
      else
        @name = nm
      end
    end

    # An avro name must
    # * start with [A-Za-z_]
    # * subsequently contain only [A-Za-z0-9_]
    def validate_name nm
      (nm =~ /\A[A-Za-z_]\w*\z/) or raise "An avro name must start with [A-Za-z_] and contain only [A-Za-z0-9_]. A namespace is the dot-separated sequence of such names."
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
  end

  #
  # Describes a field in an Avro Record object.
  #
  # Each field has the following attributes:
  # * name:     a string providing the name of the field (required), and
  # * doc:      a string describing this field for users (optional).
  # * type:     a Type object defining a schema, or a string or symbol naming a
  #             record definition (required).
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
    rcvr_accessor :name,      String, :required => true
    rcvr_accessor :doc,       String
    rcvr_accessor :type,      String, :required => true
    rcvr_accessor :default,   Object # accept and love the object just as it is
    rcvr          :order,     String

    ALLOWED_ORDERS = %w[ascending descending ignore]
    def order
      @order || 'ascending'
    end
    def order_direction
      case order when 'ascending' then 1 when 'descending' then -1 else 0 ; end
    end
    # QUESTION: should this be an override of order=, or of receive_order?
    def order= v
      raise "'order' may only take the values ascending (the default), descending, or ignore." unless v.nil? || ALLOWED_ORDERS.include?(v)
      self.order = v
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
    rcvr_accessor :fields, Array, :of => Icss::TypeFactory, :required => true

    # def ruby_klass
    #   @klass ||= Class.new do
    #     fields.each do |field|
    #       instance_eval{ field.define_receiver }
    #     end
    #   end
    # end

    #
    # Conversion
    #
    def to_hash
      super.merge( :fields => (fields||[]).map{|field| field.to_hash} )
    end
  end

  #  An error definition is just like a record definition except it uses "error" instead of "record".
  class ErrorType < RecordType
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
  class ArrayType < Type
    # FIXME: is items required? The schema doesn't say so.
    rcvr_accessor :items, TypeFactory
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
  class MapType < Type
    # FIXME: is items required? The schema doesn't say so.
    rcvr_accessor :values, TypeFactory
  end
  HashType = MapType

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
  class UnionType < Type
    def receive *args
      raise "Not implemented yet"
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
  class FixedType < Type
    rcvr_accessor :size, Integer, :required => true
  end

  #
  #
  #
  class TypeFactory < Type
    # I feel like the case statement below could be improved...
    def self.receive hsh
      hsh = hsh.symbolize_keys
      type = hsh[:type].to_sym
      # p [self, 'receive', type, hsh, Icss::Type::DERIVED_TYPES]
      case
      when primitive?(type)
        find(type).receive(hsh)
      when type == :record
        klass = build_record_type(hsh)
        klass.receive(hsh)
      when obj = self.find(type)
        obj.receive(hsh)
      else
        raise "hell"
      end
    end

    def self.build_record_type hsh
      klass_name = hsh[:name].to_s.classify+"Type"
      klass = Icss::Type.const_set(klass_name, Class.new(Icss::RecordType))
      # FIXME: doesn't follow receive pattern
      klass.name = hsh[:name].to_s.to_sym if hsh[:name]
      klass.doc  = hsh[:doc]              if hsh[:doc]
      klass.type = :record
      ::Icss::Type::DERIVED_TYPES[hsh[:name].to_sym] = klass
    end
  end

  Type.class_eval do
    PRIMITIVE_TYPES  = {
      :null    => NilClassType,
      :boolean => BooleanType,
      :string  => StringType,
      :bytes   => BytesType,
      :int     => IntegerType,
      :long    => LongType,
      :float   => FloatType,
      :double  => DoubleType,
    }.freeze unless defined?(PRIMITIVE_TYPES)
    NAMED_TYPES      = {
      :fixed   => :fixed,
      :enum    => :enum,
      :record  => RecordType,
      :error   => :error
    }.freeze unless defined?(NAMED_TYPES)
    ENUMERABLE_TYPES = {
      :array   => Array,
      :map     => :map,
      :union   => :union,
      :request => :request,
    }.freeze unless defined?(ENUMERABLE_TYPES)
    VALID_TYPES     = (PRIMITIVE_TYPES.merge(NAMED_TYPES.merge(ENUMERABLE_TYPES))).freeze unless defined?(VALID_TYPES)
    VALID_TYPES.each{|n, t| t.name = n if n.is_a?(Icss::Type) }
  end
end
