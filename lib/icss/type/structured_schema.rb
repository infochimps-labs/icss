module Icss
  module Meta

    class NamedSchema
      include Icss::Meta::RecordModel
      include Icss::ReceiverModel::ActsAsHash
      include Gorillib::Hashlike
      include Gorillib::Hashlike::TreeMerge
      field     :type,     String, :required => true
      field     :fullname, Symbol, :required => true
      alias_method :receive_name, :receive_fullname

      def self.get_klass_name(schema)
        schema[:name]
      end
    end

    class StructuredSchema < NamedSchema
      class_attribute :superclass_for_klasses
      class_attribute :metatype_for_klasses

      # * create a schema writer object.
      # * generate a named class to represent the type
      # * add class attributes by extending with the provided type module
      # * inscribe
      #
      def self.receive(schema)
        schema_obj = super(schema)
        schema_obj.fullname ||= get_klass_name(schema)
        model_klass = Icss::Meta::NamedType.get_model_klass(schema_obj.fullname, superclass_for_klasses)
        #
        model_klass.extend ::Icss::Meta::NamedType
        model_klass.extend metatype_for_klasses
        schema_obj.inscribe_schema(model_klass)
        model_klass
      end

      def inscribe_schema(model_klass)
        schema_writer = self
        model_type = model_klass.singleton_class
        model_type.class_eval{ define_method(:_schema){ schema_writer } }
        self.class.field_names.each do |attr|
          val = self.send(attr)
          model_type.class_eval{ define_method(attr){ val } }
        end
      end
    end

    # -------------------------------------------------------------------------
    #
    # Container Types (array, map and union)
    #

    #
    # ArrayType provides the behavior an Array type.
    #
    # Arrays use the type name "array" and support a single attribute:
    #
    # * items: the schema of the array's items.
    #
    # @example, an array of strings is declared with:
    #
    #     {"type": "array", "items": "string"}
    #
    module ArrayType
      def receive(raw)
        return nil if raw.nil? || (raw == "")
        self.new( raw.map{|raw_item| item_factory.receive(raw_item) } )
      end
      #
      def to_schema()
        (defined?(super) ? super() : {}).merge({ :type => self.type, :items => self.items })
      end
    end

    #
    # ArraySchema describes an Array type (as opposed to ArrayType, which
    # implements it)
    #
    # Arrays use the type name "array" and support a single attribute:
    #
    # * items: the schema of the array's items.
    #
    # @example, an array of strings is declared with:
    #
    #     {"type": "array", "items": "string"}
    #
    class ArraySchema < ::Icss::Meta::StructuredSchema
      self.superclass_for_klasses = Array
      self.metatype_for_klasses   = ::Icss::Meta::ArrayType
      field     :items,        Object, :required => true
      field     :item_factory, Icss::Meta::TypeFactory
      after_receive{|hsh| self.receive_item_factory(self.items) }
      #
      def self.get_klass_name(schema)
        return if super(schema)
        slug = Icss::Meta::Type.klassname_for(schema[:items]) or return
        slug = slug.gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
        "ArrayOf#{slug}"
      end
    end

    module HashType
      def receive(raw)
        return nil if raw.nil? || (raw == "")
        obj = self.new
        raw.each{|rk,rv| obj[rk] = value_factory.receive(rv) }
        obj
      end
      #
      def to_schema()
        (defined?(super) ? super() : {}).merge({ :type => self.type, :values => self.values })
      end
    end

    #
    # HashSchema describes an Avro Map type (which corresponds to a Ruby
    # Hash).
    #
    # Hashes use the type name "hash" (or "map") and support one attribute:
    #
    # * values: the schema of the map's values. Avro Map keys are assumed to be strings.
    #
    # @example, a map from string to long is declared with:
    #
    #     {"type": "map", "values": "long"}
    #
    class HashSchema < ::Icss::Meta::StructuredSchema
      self.superclass_for_klasses = Hash
      self.metatype_for_klasses   = ::Icss::Meta::HashType
      field     :values,        Object, :required => true
      field     :value_factory, Icss::Meta::TypeFactory
      after_receive{|hsh| self.receive_value_factory(self.values) }
      #
      def self.get_klass_name(schema)
        return if super(schema)
        slug = Icss::Meta::Type.klassname_for(schema[:values]) or return
        slug = slug.gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
        "HashOf#{slug}"
      end
      def self.receive(*args)
        val = super(*args)
        raise "Value Factory is no good: #{args} - #{val._schema.to_hash}" if val.value_factory.blank?
        val
      end
    end # HashSchema

    module EnumType
      def receive(raw)
        obj = super(raw) or return
        unless self.symbols.include?(obj) then raise ArgumentError, "Cannot receive #{raw}: must be one of #{symbols[0..2].join(',')}#{symbols.length > 3 ? ",..." : ""}" ; end
        obj
      end
      #
      def to_schema()
        { :type => self.type, :name => self.fullname, :symbols => self.symbols }
      end
    end

    #
    # An EnumSchema escribes an Enum type.
    #
    # Enums use the type name "enum" and support the following attributes:
    #
    # name:       a string providing the name of the enum (required).
    # namespace:  a string that qualifies the name;
    # doc:        a string providing documentation to the user of this schema (optional).
    # symbols:    an array, listing symbols, as strings or ruby symbols (required). All
    #             symbols in an enum must be unique; duplicates are prohibited.
    #
    # For example, playing card suits might be defined with:
    #
    # { "type": "enum",
    #   "name": "Suit",
    #   "symbols" : ["SPADES", "HEARTS", "DIAMONDS", "CLUBS"]
    # }
    #
    class EnumSchema < ::Icss::Meta::StructuredSchema
      self.superclass_for_klasses = Symbol
      self.metatype_for_klasses   = ::Icss::Meta::EnumType
      field     :symbols, :array,  :items => Symbol, :required => true
    end # EnumSchema

    #
    # A Fixed type.
    #
    # Fixed uses the type name "fixed" and supports the attributes:
    #
    # * name: a string naming this fixed (required).
    # * namespace, a string that qualifies the name;
    # * size: an integer, specifying the number of bytes per value (required).
    #
    #   For example, 16-byte quantity may be declared with:
    #
    #     {"type": "fixed", "size": 16, "name": "md5"}
    #
    module FixedType
      # Error thrown when a FixedType is given too few/many bytes
      class FixedValueWrongSizeError < ArgumentError ; end
      # accept like a string but enforce (violently) the length constraint
      def receive(raw)
        obj = super(raw) ; return nil if obj.blank?
        unless obj.bytesize == self.size then raise FixedValueWrongSizeError.new("Wrong size for a fixed-length type #{self.fullname}: got #{obj.bytesize}, not #{self.size}") ; end
        obj
      end
      #
      def to_schema()
        { :type => self.type, :name => self.fullname, :size => self.size }
      end
    end

    #
    # Description of an Fixed type.
    #
    # Fixed uses the type name "fixed" and supports the attributes:
    #
    # * name: a string naming this fixed (required).
    # * namespace, a string that qualifies the name;
    # * size: an integer, specifying the number of bytes per value (required).
    #
    #   For example, 16-byte quantity may be declared with:
    #
    #     {"type": "fixed", "size": 16, "name": "md5"}
    #
    class FixedSchema < ::Icss::Meta::StructuredSchema
      self.superclass_for_klasses = String
      self.metatype_for_klasses   = ::Icss::Meta::FixedType
      field     :size,    Integer, :validates => { :numericality => { :greater_than => 0 }}
    end # FixedSchema

  end
end
