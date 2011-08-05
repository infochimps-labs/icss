unless defined?(Boolean) then class Boolean ; end ; end
unless defined?(Binary)  then class Binary  < String ; end ; end

module Icss
  module Meta

    Icss::Meta::DERIVED_TYPES = {} unless defined?(Icss::Type::DERIVED_TYPES)

    unless defined?(Icss::Meta::PRIMITIVE_TYPES)
      Icss::Meta::PRIMITIVE_TYPES = {
        :null    => NilClass,
        :boolean => Boolean,
        :int     => Integer,
        :long    => Integer,
        :float   => Float,
        :double  => Float,
        :bytes   => Binary,
        :string  => String,
      }.freeze
    end

    unless defined?(::Icss::Meta::SIMPLE_TYPES)
      Icss::Meta::SIMPLE_TYPES = Icss::Meta::PRIMITIVE_TYPES.merge({
          :symbol    => Symbol,
          :time      => Time,
          :date      => Date,
        })
    end

    TYPE_ALIASES = {
      :null    => NilClass,
      :boolean => Boolean,
      :string  => String,  :bytes   => String,
      :symbol  => Symbol,
      :int     => Integer, :integer => Integer,  :long    => Integer,
      :time    => Time,    :date    => Date,
      :float   => Float,   :double  => Float,
      :hash    => Hash,    :map     => Hash,
      :array   => Array,
    } unless defined?(TYPE_ALIASES)


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
end
