module Icss

  # full definitions in type/simple_types.rb
  class ::Boolean < ::BasicObject ; end
  class ::Long    < ::Integer     ; end
  class ::Double  < ::Float       ; end
  class ::Binary  < ::String      ; end

  # full definitions in type/record_type.rb and type/structured_schemas.rb
  module Meta
    module NamedSchema  ; class Writer ; end ; end
    module RecordSchema ; class Writer < NamedSchema::Writer ; end ; end
    module ErrorSchema  ; class Writer < NamedSchema::Writer ; end ; end
    module HashSchema   ; class Writer < NamedSchema::Writer ; end ; end
    module ArraySchema  ; class Writer < NamedSchema::Writer ; end ; end
    module FixedSchema  ; class Writer < NamedSchema::Writer ; end ; end
    module EnumSchema   ; class Writer < NamedSchema::Writer ; end ; end
    module UnionSchema  ; class Writer < NamedSchema::Writer ; end ; end
  end


  # patron saint of Simple Types (Structured Text)
  module St ; end
  # pasture wherein graze MeasurementUnits
  module Mu ; end



  ::Icss::SIMPLE_TYPES    = {} unless defined?( ::Icss::SIMPLE_TYPES  )
  ::Icss::STRUCTURED_SCHEMAS   = {} unless defined?( ::Icss::STRUCTURED_SCHEMAS )
  ::Icss::RECORD_TYPES    = {} unless defined?( ::Icss::RECORD_TYPES  )
  ::Icss::UNION_SCHEMAS     = {} unless defined?( ::Icss::UNION_SCHEMAS   )
  ::Icss::FACTORY_TYPES   = {} unless defined?( ::Icss::FACTORY_TYPES )

  unless defined?(::Icss::AVRO_TYPES)
    ::Icss::AVRO_TYPES = {
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

  ::Icss::SIMPLE_TYPES.merge!(::Icss::AVRO_TYPES)
  ::Icss::SIMPLE_TYPES.merge!({
      :binary  => ::Binary,
      :symbol  => ::Symbol,
      :time    => ::Time,
      :integer => ::Integer,
    })

  ::Icss::STRUCTURED_SCHEMAS.merge!({
      :record  => Icss::Meta::RecordSchema::Writer,
      :error   => Icss::Meta::ErrorSchema::Writer,
      :map     => Icss::Meta::HashSchema::Writer,
      Hash     => Icss::Meta::HashSchema::Writer,
      :array   => Icss::Meta::ArraySchema::Writer,
      Array    => Icss::Meta::ArraySchema::Writer,
      :fixed   => Icss::Meta::FixedSchema::Writer,
      :enum    => Icss::Meta::EnumSchema::Writer,
    })
  ::Icss::UNION_SCHEMAS.merge!({
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
      #   null boolean integer long float double string binary
      #   st.file_path st.regexp st.url st.epoch_time
      # and so forth
      #
      # note this takes no account of inheritance -- only the types specifically
      # listed in Icss::SIMPLE_TYPES are simple
      def self.simple?(tt)    ::Icss::SIMPLE_TYPES.has_value?(tt)    ; end

      def self.union?(tt)     false     ; end

      def self.record?(tt)    false     ; end
    end

  end
end


