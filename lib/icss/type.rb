unless defined?(Boolean) then class Boolean ; end ; end
unless defined?(Binary)  then class Binary  < String ; end ; end

module Icss
  module Type

    unless defined?(Icss::Type::PRIMITIVE_TYPES)
      Icss::Type::PRIMITIVE_TYPES = {
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

    unless defined?(::Icss::Type::SIMPLE_TYPES)
      Icss::Type::SIMPLE_TYPES = Icss::Type::PRIMITIVE_TYPES.merge({
          :symbol    => Symbol,
          :time      => Time,
          :date      => Date,
        })
    end

    unless defined?(TYPE_ALIASES)
      TYPE_ALIASES = {
        :null    => NilClass,
        :boolean => Boolean,
        :int     => Integer, :integer => Integer,  :long    => Integer,
        :float   => Float,   :double  => Float,
        :string  => String,  :bytes   => Binary,
        #
        :hash    => Hash,    :map     => Hash,
        :array   => Array,
        #
        :symbol  => Symbol,
        :time    => Time,    :date    => Date,
        :object  => Object,
      }
    end

    # ::Icss::Type::DERIVED_TYPES = {} unless defined?(::Icss::Type::DERIVED_TYPES)
    # Icss::Type::VALID_TYPES  = (Icss::Type::PRIMITIVE_TYPES.merge(Icss::Type::NAMED_TYPES.merge(Icss::Type::ENUMERABLE_TYPES))).freeze unless defined?(Icss::Type::VALID_TYPES)
    # Icss::Type::VALID_TYPES.each{|n, t| t.name = n if t.is_a?(Icss::Type) }
  end
end
