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
  class Type
    include Receiver
    rcvr_accessor :name,       String
    rcvr_accessor :doc,        String
    rcvr_accessor :ruby_klass, Object
    rcvr_accessor :validates,  Hash

    Icss::Type::DERIVED_TYPES = {} unless defined?(Icss::Type::DERIVED_TYPES)


    def self.find type_name
      if type_name.is_a?(String) && type_name.include?('.')
        ReferencedType.receive(type_name)
        type_name = type_name.split('.').pop
      end
      Icss::Type::VALID_TYPES[type_name.to_sym] || Icss::Type::DERIVED_TYPES[type_name.to_sym] || type_name
    end

    def self.primitive? name
      PRIMITIVE_TYPES.include?(name.to_sym)
    end

    def primitive?() false ; end

    def title() self.name ; end

    def to_hash() { :name => name, :doc => doc }.reject{ |k,v| v.nil? } ; end

    def to_json() to_hash.to_json ; end
  end

  # ---------------------------------------------------------------------------
  #
  # Primitive Types
  #

  class PrimitiveType < Type
    def to_hash() name.to_s ; end
    def primitive?() true ; end
  end

  unless defined?(::Icss::Type::PRIMITIVE_TYPES)
    ::Icss::Type::PRIMITIVE_TYPES = {}
    ::Icss::Type::PRIMITIVE_TYPES[:null]    = PrimitiveType.receive(:ruby_klass => NilClass, :pig_name => 'FIXME WHAT GOES HERE' )
    ::Icss::Type::PRIMITIVE_TYPES[:boolean] = PrimitiveType.receive(:ruby_klass => Boolean,  :pig_name => 'FIXME WHAT GOES HERE')
    ::Icss::Type::PRIMITIVE_TYPES[:string]  = PrimitiveType.receive(:ruby_klass => String,   :pig_name => 'chararray',:mysql_name => 'VARCHAR')
    ::Icss::Type::PRIMITIVE_TYPES[:bytes]   = PrimitiveType.receive(:ruby_klass => String,   :pig_name => 'bytearray',:mysql_name => 'VARCHAR')
    ::Icss::Type::PRIMITIVE_TYPES[:int]     = PrimitiveType.receive(:ruby_klass => Integer,  :pig_name => 'int',:mysql_name => 'INT')
    ::Icss::Type::PRIMITIVE_TYPES[:long]    = PrimitiveType.receive(:ruby_klass => Integer,  :pig_name => 'long',:mysql_name => 'BIGINT')
    ::Icss::Type::PRIMITIVE_TYPES[:float]   = PrimitiveType.receive(:ruby_klass => Float,    :pig_name => 'float',:mysql_name => 'FLOAT')
    ::Icss::Type::PRIMITIVE_TYPES[:double]  = PrimitiveType.receive(:ruby_klass => Float,    :pig_name => 'double',:mysql_name => 'DOUBLE')
    #
    ::Icss::Type::PRIMITIVE_TYPES[:symbol]  = PrimitiveType.receive(:ruby_klass => Symbol,   :pig_name => 'chararray')
    ::Icss::Type::PRIMITIVE_TYPES[:time]    = PrimitiveType.receive(:ruby_klass => Time,     :pig_name => 'chararray')
    ::Icss::Type::PRIMITIVE_TYPES[:date]    = PrimitiveType.receive(:ruby_klass => Date,     :pig_name => 'chararray')

    ::Icss::Type::PRIMITIVE_TYPES[:url]      = PrimitiveType.receive(:ruby_klass => String, :validates => { :format => { :with => /\.com$/ }})
    ::Icss::Type::PRIMITIVE_TYPES[:duration] = PrimitiveType.receive(:ruby_klass => Time,   :validates => { :format => { :with => // }})

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
  class NamedType < Type
    rcvr_accessor :namespace, String
    attr_accessor :parent
    # the avro base type name
    class_attribute :type

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

    # If the namespace is given in the name (using a dotted name string) then
    # any namespace also specified is ignored.
    def receive_namespace nmsp
      if @namespace then warn "Warning: namespace already set, ignoring" and return ; end
      @namespace = nmsp
    end
    def namespace
      @namespace || (parent ? parent.namespace : "")
    end

    # If no explicit namespace is specified, the namespace is taken from the
    # most tightly enclosing schema or protocol. For example, if "name": "X" is
    # specified, and this occurs within a field of the record definition of
    # org.foo.Y, then the fullname is org.foo.X.
    #
    def fullname
      [namespace, name].reject(&:blank?).join('.')
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
      case
      when type_info.is_a?(Icss::Type)
        type_info
      when type_info.is_a?(String) || type_info.is_a?(Symbol)
        Icss::Type.find(type_info)
      when type_info.is_a?(Array)
        UnionType.receive(type_info)
      else
        type_info = type_info.symbolize_keys
        raise "No type was given in #{type_info.inspect}" if type_info[:type].blank?
        type_name = type_info[:type].to_sym
        type = Icss::Type.find(type_name)
        obj = type.receive(type_info)
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
  # * required: raises an error if the field is unset when validate! is called
  #
  # See RecordType for examples.
  #
  class RecordField
    include Receiver
    include Receiver::ActsAsHash
    include Receiver::ActiveModelShim

    rcvr_accessor :name,      String, :required => true
    rcvr_accessor :doc,       String
    attr_accessor :type # work around a bug in ruby 1.8, which has defined (and deprecated) type
    rcvr_accessor :type,      String, :required => true

    rcvr_accessor :default,   Object
    rcvr          :order,     String
    rcvr_accessor :required,  Boolean

    rcvr_accessor :validates, Hash

    attr_accessor :is_reference

    def type
      return @type if @type.is_a?(Icss::Type)
      @type = Icss::Type::DERIVED_TYPES[@type.to_sym]
      @type
    end

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


    def record?() type.is_a? Icss::RecordType end
    def union?()  type.is_a? Array            end
    def enum?()   type.is_a? Icss::EnumType   end

    def to_hash()
      { :name    => name,
        :type    => expand_type,
        :default => default,
        :order   => @order,
        :doc     => doc,
      }.reject{|k,v| v.nil? }
    end

    def expand_type
      case
      when is_reference? && type.respond_to?(:name) then type.name
      when is_reference?                            then '(_unspecified_)'
      when type.is_a?(Array) then type.map{|t| t.to_hash }
      when type.respond_to?(:to_hash) then type.to_hash
      else type.to_s
      end
    end
  end

  require 'icss/type/complex_types'

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
    }.freeze unless defined?(Icss::Type::ENUMERABLE_TYPES)
    Icss::Type::VALID_TYPES  = (Icss::Type::PRIMITIVE_TYPES.merge(Icss::Type::NAMED_TYPES.merge(Icss::Type::ENUMERABLE_TYPES))).freeze unless defined?(Icss::Type::VALID_TYPES)
    Icss::Type::VALID_TYPES.each{|n, t| t.name = n if t.is_a?(Icss::Type) }
  end
end
