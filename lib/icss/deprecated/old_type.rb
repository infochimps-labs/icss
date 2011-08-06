

module Icss


  # class Type
  #   include Receiver
  #   rcvr_accessor :validates,  Hash
  #
  #   def self.find typename
  #     Icss::Type::VALID_TYPES[typename.to_sym] || Icss::Type::DERIVED_TYPES[typename.to_sym] || typename
  #   end
  #
  #   def self.primitive? name
  #     PRIMITIVE_TYPES.include?(name.to_sym)
  #   end
  #
  #   def primitive?() false ; end
  #
  #   def title() self.name ; end
  #
  #   def to_hash() { :name => name, :doc => doc }.reject{ |k,v| v.nil? } ; end
  #
  #   def to_json() to_hash.to_json ; end
  # end

  # ---------------------------------------------------------------------------
  #
  # Primitive Types
  #

  # class PrimitiveType < Type
  #   def to_hash() name.to_s ; end
  #   def primitive?() true ; end
  # end

  # ---------------------------------------------------------------------------
  #
  # Complex Types
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

  require 'icss/type/complex_types'

  Type.class_eval do
    Icss::Type::NAMED_TYPES      = {
      :fixed   => FixedType,
      :enum    => EnumType,
      :record  => RecordType,
      :error   => ErrorType
    }.freeze unless defined?(Icss::Type::NAMED_TYPES)
    Icss::Type::CONTAINER_TYPES = {
      :array   => ArrayType,
      :map     => HashType,
      :union   => UnionType,
    }.freeze unless defined?(Icss::Type::CONTAINER_TYPES)
    Icss::Type::VALID_TYPES  = (Icss::Type::PRIMITIVE_TYPES.merge(Icss::Type::NAMED_TYPES.merge(Icss::Type::CONTAINER_TYPES))).freeze unless defined?(Icss::Type::VALID_TYPES)
    Icss::Type::VALID_TYPES.each{|n, t| t.name = n if t.is_a?(Icss::Type) }
  end
end
