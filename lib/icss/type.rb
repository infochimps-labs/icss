module Icss

  class Type
    include Receiver
    rcvr_accessor :name,       String
    rcvr_accessor :doc,        String
    rcvr_accessor :ruby_klass, Object

    Icss::Type::DERIVED_TYPES = {} unless defined?(Icss::Type::DERIVED_TYPES)

    def self.find type_name
      if type_name.to_s.include?('.')
        warn "crap. can't properly do namespaced types yet."
        type_name = type_name.to_s.gsub(/(.*)\./, "")
      end
      Icss::Type::VALID_TYPES[type_name.to_sym] || Icss::Type::DERIVED_TYPES[type_name.to_sym]
    end

    def self.primitive? name
      PRIMITIVE_TYPES.include?(name.to_sym)
    end

    def primitive?() false ; end

    def title() self.name ; end

    def to_hash() { :name => name, :doc => doc }.reject{ |k,v| v.nil? } ; end

    def to_json() to_hash.to_json ; end
  end

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
    ::Icss::Type::PRIMITIVE_TYPES.freeze
  end

  class NamedType < Type
    rcvr_accessor :namespace, String
    attr_accessor :parent
    # the avro base type name
    class_attribute :type

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
      if @namespace then warn "Warning: namespace already set, ignoring" and return ; end
      @namespace = nmsp
    end

    def namespace
      @namespace || (parent ? parent.namespace : "")
    end

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
        type_info  = type_info.symbolize_keys
        raise "No type was given in #{type_info.inspect}" if type_info[:type].blank?
        type_name = type_info[:type].to_sym
        type = Icss::Type.find(type_name)
        obj  = type.receive(type_info)
      end
    end

  end

  class RecordField
    include Receiver
    include Receiver::ActsAsHash

    rcvr_accessor :name,      String, :required => true
    rcvr_accessor :doc,       String
    attr_accessor :type # work around a bug in ruby 1.8, which has defined (and deprecated) type
    rcvr_accessor :type,      Icss::Type, :required => true

    rcvr_accessor :default,   Object
    rcvr          :order,     String
    rcvr_accessor :required,  Boolean

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
