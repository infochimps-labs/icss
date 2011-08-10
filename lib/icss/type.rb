module Icss

  # full definitions in type/primitive_types.rb
  class ::Boolean < ::BasicObject ; end
  class ::Long    < ::Integer     ; end
  class ::Double  < ::Float       ; end
  class ::Binary  < ::String      ; end

  # full definitions in type/record_type.rb and type/complex_types.rb
  module Meta
    module RecordType  ; class Schema ; class Writer ; end ; end ; end
    module ErrorType   ; class Schema ; class Writer ; end ; end ; end
    module HashSchema  ; class Writer ; end ; end
    module ArraySchema ; class Writer ; end ; end
    module FixedSchema ; class Writer ; end ; end
    module EnumSchema  ; class Writer ; end ; end
    module UnionSchema ; class Writer ; end ; end
  end

  ::Icss::SIMPLE_TYPES    = {} unless defined?( ::Icss::SIMPLE_TYPES  )
  ::Icss::COMPLEX_TYPES   = {} unless defined?( ::Icss::COMPLEX_TYPES )
  ::Icss::RECORD_TYPES    = {} unless defined?( ::Icss::RECORD_TYPES  )
  ::Icss::UNION_TYPES     = {} unless defined?( ::Icss::UNION_TYPES   )
  ::Icss::FACTORY_TYPES   = {} unless defined?( ::Icss::FACTORY_TYPES )

  unless defined?(::Icss::PRIMITIVE_TYPES)
    ::Icss::PRIMITIVE_TYPES = {
      :null     => ::NilClass,
      :boolean  => ::Boolean,
      :int      => ::Integer,
      :long     => ::Long,
      :float    => ::Float,
      :double   => ::Double,
      :string   => ::String,
      :bytes    => ::Binary,
    }.freeze
  end
  ::Icss::COMPLEX_TYPES.merge!({
      :record  => Icss::Meta::RecordType::Schema::Writer,
      :error   => Icss::Meta::ErrorType::Schema::Writer,
      :map     => Icss::Meta::HashSchema::Writer,
      Hash     => Icss::Meta::HashSchema::Writer,
      :array   => Icss::Meta::ArraySchema::Writer,
      Array    => Icss::Meta::ArraySchema::Writer,
      :fixed   => Icss::Meta::FixedSchema::Writer,
      :enum    => Icss::Meta::EnumSchema::Writer,
    })
  ::Icss::UNION_TYPES.merge!({
      :union   => Icss::Meta::UnionSchema::Writer,
    })

  module Meta

    module Type
      #:nodoc:
      NORMAL_NAMED_CONSTANT_RE = /\A[\w\:\.]+\z/

      # Turns a type name into its dotted (avro-style) name, regardless of its
      # current form.
      #
      # @example
      #    Icss::Meta::Type.fullname_for(Icss::This::That::TheOther)   # 'this.that.the_other'
      #    Icss::Meta::Type.fullname_for("Icss::This::That::TheOther") # 'this.that.the_other'
      #    Icss::Meta::Type.fullname_for('this.that.the_other')        # 'this.that.the_other'
      #
      def self.fullname_for(klass_name)
        return nil unless klass_name.present? && (klass_name.to_s =~ NORMAL_NAMED_CONSTANT_RE)
        klass_name.to_s.gsub(/^:*Icss::/, '').underscore.gsub(%r{/},".")
      end

      # Converts a type name to its ruby (camel-cased) form. Works on class,
      # name of class, or dotted (avro-style) namespace.name. Names will have
      # an 'Icss::' prefix.
      #
      # @example
      #    Icss::Meta::Type.fullname_for('this.that.the_other')        # "Icss::This::That::TheOther"
      #    Icss::Meta::Type.fullname_for(Icss::This::That::TheOther)   # "Icss::This::That::TheOther"
      #    Icss::Meta::Type.fullname_for("Icss::This::That::TheOther") # "Icss::This::That::TheOther"
      #
      def self.klassname_for(fullname)
        return nil unless fullname.present? && (fullname.to_s =~ NORMAL_NAMED_CONSTANT_RE)
        nm = fullname.to_s.gsub(/^:*Icss:+/, '').
          gsub(%r{::},'.').
          split('.').map(&:camelize).join('::')
        "::Icss::#{nm}"
      end

      # true if class is among the defined primitive types:
      #   null boolean int long float double string bytes
      #
      # note this takes no account of inheritance -- a descendant of String is not primitive.
      def self.primitive?(tt) ::Icss::PRIMITIVE_TYPES.has_value?(tt) ; end

      # true if class is among the defined simple types: the primitive types, plus
      #   text file_path regexp url epoch_time
      #
      # note this takes no account of inheritance -- only the types specifically
      # listed in Icss::SIMPLE_TYPES are simple
      def self.simple?(tt)    ::Icss::SIMPLE_TYPES.has_value?(tt)    ; end

      def self.union?(tt)     false     ; end

      def self.record?(tt)    false     ; end
    end

  end
end


