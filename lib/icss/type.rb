module Icss

  #
  # Predefining the namespaces here makes inclusion-order less brittle.
  #

  # full definitions in type/simple_types.rb
  class ::Boolean < ::BasicObject ; end
  class ::Long    < ::Integer     ; end
  class ::Double  < ::Float       ; end
  class ::Binary  < ::String      ; end

  # patron saint of Simple Types (Structured Text)
  module St       ; end
  # pasture wherein graze MeasurementUnits
  module Mu       ; end
  # stand in the place where you are
  module Business ;  end
  #
  module Culture  ;  end
  # Eventfully, Tom phoned the caterer.
  module Ev       ; end
  #
  module Geo      ; end
  # Relatively speaking, this is where links and relations go
  module Rel      ; end
  # I don't want to sell anything, buy anything, or process anything as a career.
  # I don't want to sell anything bought or processed, or buy anything sold or processed, or process
  # anything sold, bought, or processed, or repair anything sold, bought, or processed.
  # You know, as a career, I don't want to do that.
  module Prod     ;  end
  #
  module Social   ; end
  #
  module Web      ; end

  # Buffalo Buffalo buffalo Buffalo Buffalo Buffalo buffalow.
  module Meta
    # full definitions in type/structured_schema.rb and type/union_schema.rb
    class NamedSchema  ; end
    class StructuredSchema < NamedSchema  ; end
    class HashSchema       < StructuredSchema ; end
    class ArraySchema      < StructuredSchema ; end
    class FixedSchema      < StructuredSchema ; end
    class EnumSchema       < StructuredSchema ; end
    class UnionSchema      < NamedSchema ; end
    class RecordSchema     < NamedSchema ; end
    class ErrorSchema      < RecordSchema ; end
  end

  ::Icss::SIMPLE_TYPES       = {} unless defined?( ::Icss::SIMPLE_TYPES       )
  ::Icss::FACTORY_TYPES      = {} unless defined?( ::Icss::FACTORY_TYPES      )
  ::Icss::STRUCTURED_SCHEMAS = {} unless defined?( ::Icss::STRUCTURED_SCHEMAS )
  ::Icss::UNION_SCHEMAS      = {} unless defined?( ::Icss::UNION_SCHEMAS      )

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
      :record  => Icss::Meta::RecordSchema,
      :error   => Icss::Meta::ErrorSchema,
      :map     => Icss::Meta::HashSchema,
      Hash     => Icss::Meta::HashSchema,
      :array   => Icss::Meta::ArraySchema,
      Array    => Icss::Meta::ArraySchema,
      :fixed   => Icss::Meta::FixedSchema,
      :enum    => Icss::Meta::EnumSchema,
    })
  ::Icss::UNION_SCHEMAS.merge!({
      :union   => Icss::Meta::UnionSchema,
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

      CATALOG_PATH = 'examples/infochimps_catalog/core'
      def self.load_type(typename)
        filename = ENV.root_path(CATALOG_PATH, typename.to_s.gsub(/\./, '/').gsub(/(\.icss\.yaml)?$/, ".icss.yaml"))
        protocol_hsh = YAML.load(File.open(filename))
        protocol_hsh[:types].map do |schema_hsh|
          schema_hsh[:is_a] && schema_hsh[:is_a].reject!{|x| x.to_s =~ /meta\.record_type/}
          model = Icss::Meta::TypeFactory.receive(schema_hsh)
        end
      end
    end
  end
end
