module Icss

  module Meta
    module Type

      def self.fullname_for(klass_name)
        klass_name.to_s.gsub(/^:*Icss::/, '').underscore.gsub(%r{/},".")
      end
      def self.klassname_for(fullname)
        nm = fullname.to_s.
          gsub(%r{::},'.').gsub(/^:*icss[\.:]+/i, '').
          split('.').map(&:camelize).join('::')
        "::Icss::#{nm}"
      end

      def fullname
        ::Icss::Meta::Type.fullname_for(self.name)
      end
      def typename
        @typename  ||= fullname.gsub(/.*[\.]/, "")
      end
      def namespace
        @namespace ||= fullname.gsub(/\.[^\.]+/, "")
      end

       def doc() "" ; end

      def to_schema
        {}
      end

      def self.primitive?(tt) ::Icss::PRIMITIVE_TYPES.has_value?(tt) ; end
      def self.simple?(tt)    ::Icss::SIMPLE_TYPES.has_value?(tt)    ; end
      def self.union?(tt)     false     ; end
      def self.record?(tt)    false     ; end

      def self.find_in_type_collection(type_collection, kind, typename)
        type_collection[typename.to_sym] or raise(ArgumentError, "No such #{kind} type #{typename}")
      end

    end
    module SimpleType
      include Icss::Meta::Type
      def namespace()  ''       ; end
      def typename()   fullname ; end
      def to_schema()  fullname ; end

      def self.make(typename)
        Icss::Meta::Type.find_in_type_collection(::Icss::SIMPLE_TYPES, :simple, typename)
      end
    end
    module PrimitiveType
      include Icss::Meta::Type
      include Icss::Meta::SimpleType

      def self.make(typename)
        Icss::Meta::Type.find_in_type_collection(::Icss::PRIMITIVE_TYPES, :primitive, typename)
      end
    end
  end

  class NilClassType < ::NilClass          ; extend ::Icss::Meta::PrimitiveType ; def self.new(val=nil) raise(ArgumentError, "#{self} must be initialized with nil") unless val.nil? ; nil ; end ; end
  class BooleanType  < ::BasicObject       ; extend ::Icss::Meta::PrimitiveType ; end
  class IntegerType  < ::Integer           ; extend ::Icss::Meta::PrimitiveType ; def self.new(val=nil) val.nil? ? nil : Integer(val) ; end ; end
  class LongType     < ::Icss::IntegerType ; extend ::Icss::Meta::PrimitiveType ; end
  class FloatType    < ::Float             ; extend ::Icss::Meta::PrimitiveType ; def self.new(val=nil) val.nil? ? nil : Float(val)   ; end ; end
  class DoubleType   < ::Icss::FloatType   ; extend ::Icss::Meta::PrimitiveType ; end
  class StringType   < ::String            ; extend ::Icss::Meta::PrimitiveType ; end
  class BinaryType   < ::Icss::StringType  ; extend ::Icss::Meta::PrimitiveType ; end

  class SymbolType   < ::Symbol            ; extend ::Icss::Meta::SimpleType ; def self.new(val=nil) val.nil? ? nil : val.to_sym ; end ; end
  class TimeType     < ::Time              ; extend ::Icss::Meta::SimpleType ; end
  class DateType     < ::Date              ; extend ::Icss::Meta::SimpleType ; end

  unless defined?(::Icss::PRIMITIVE_TYPES)
    ::Icss::PRIMITIVE_TYPES = {
      :null     => ::Icss::NilClassType,
      :boolean  => ::Icss::BooleanType,
      :int      => ::Icss::IntegerType,
      :long     => ::Icss::LongType,
      :float    => ::Icss::FloatType,
      :double   => ::Icss::DoubleType,
      :string   => ::Icss::StringType,
      :bytes    => ::Icss::BinaryType,
    }.freeze
  end
  unless defined?(::Icss::SIMPLE_TYPES)
    ::Icss::SIMPLE_TYPES = ::Icss::PRIMITIVE_TYPES.merge({
        :symbol => ::Icss::SymbolType,
        :time   => ::Icss::TimeType,
        :date   => ::Icss::DateType,
      })
  end

  # primitive? true on all the primitive types
  # Make fullname() return the symbol key given above
  ::Icss::PRIMITIVE_TYPES.each do |sym, klass|
    klass.class_eval do klass.singleton_class.class_eval do
        define_method(:fullname){ sym }
      end ; end
  end
end
