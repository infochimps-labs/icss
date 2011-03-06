module Icss
  #
  # Generic ICSS base type
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
    rcvr :name,    String
    rcvr :doc,     String
    rcvr :type,    String
    rcvr :default, Object # accept and love the object just as it is
    # Type documentation
    class_inheritable_accessor :name, :doc
    # Schema factory
    class_inheritable_accessor :ruby_klass, :pig_name

    #
    #
    #
    class OrderEnum < String ; end

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

  class NamedType < Type
    # def initialize name
    #   ::Icss::Type::DERIVED_TYPES[name.to_sym] = self
    # end
  end

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

  #
  # Icss/Avro Record type
  #
  # A record type has fields, each of which
  #
  class RecordType < NamedType
    rcvr :fields, Array, :of => Icss::TypeFactory
    rcvr :order,  OrderEnum
    class_inheritable_accessor :doc, :type

    def ruby_klass
      @klass ||= Class.new do
        fields.each do |field|
          rcvr field.name, field.ruby_klass
        end
      end
    end

    def self.to_hash
      { :name => name, :doc => doc }
    end

    #
    # Conversion
    #
    def to_hash
      super.merge( :fields => (fields||[]).map{|field| field.to_hash} )
    end
  end

  class NilClassType < Type
    self.ruby_klass = NilClass
    self.pig_name  = 'FIXME WHAT GOES HERE' # FIXME: ??
  end
  class StringType < Type
    self.ruby_klass = String
    self.pig_name  = 'chararray'
  end
  class IntegerType < Type
    self.ruby_klass = Integer
    self.pig_name  = 'int'
  end
  class BooleanType < Type
    self.ruby_klass = Boolean
    self.pig_name  = 'FIXME WHAT GOES HERE' # FIXME: ??
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
  class FixedType < Type
    self.ruby_klass = String
    self.pig_name  = 'bytearray'
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
