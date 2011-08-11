module Icss
  module Meta

    module NamedSchema
      class Writer
        extend Icss::Meta::NamedSchema
        include Icss::Meta::RecordType
        include Icss::ReceiverModel::ActiveModelShim
        #
        field     :type,     Symbol, :required => true
        field     :fullname, Symbol
        validates :type,     :presence => true
        validates :fullname, :presence => true

        alias_method :receive_name, :receive_fullname

        def self.get_klass_name(schema)
          schema[:name]
        end

        # * create a schema writer object.
        # * create a named class to represent the type
        #
        def self.receive_schema(schema, superklass, metatype)
          schema_obj = self.receive(schema)
          schema_obj.fullname ||= get_klass_name(schema)
          type_klass = Icss::Meta::NamedSchema.get_type_klass(schema_obj.fullname, superklass)
          type_klass.class_eval{ extend(::Icss::Meta::NamedSchema) }
          type_klass.class_eval{ extend(metatype) }
          inscribe_schema(schema_obj, type_klass.singleton_class)
          type_klass
        end
      end
    end

    # -------------------------------------------------------------------------
    #
    # Container Types (array, map and union)
    #

    #
    # ArraySchema describes an Avro Array type.
    #
    # Arrays use the type name "array" and support a single attribute:
    #
    # * items: the schema of the array's items.
    #
    # @example, an array of strings is declared with:
    #
    #     {"type": "array", "items": "string"}
    #
    module ArraySchema
      def receive(raw)
        return nil if raw.nil? || (raw == "")
        self.new( raw.map{|raw_item| item_factory.receive(raw_item) } )
      end

      def to_schema()
        (defined?(super) ? super() : {}).merge({ :type => self.type, :items => self.items })
      end

      class Writer < ::Icss::Meta::NamedSchema::Writer
        field     :items,        Object
        validates :items,        :presence => true
        field     :item_factory, Icss::Meta::TypeFactory
        after_receive{|hsh| self.receive_item_factory(self.items) }

        def self.get_klass_name(schema)
          return if super(schema)
          return unless schema[:items].is_a?(Module) || schema[:items].respond_to?(:to_sym)
          items_type_name = schema[:items].to_s.to_sym
          slug = Icss::Meta::Type.klassname_for(items_type_name).gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
          "ArrayOf#{slug}"
        end

        def self.receive_schema(schema)
          super(schema, Array, ::Icss::Meta::ArraySchema)
        end
      end
    end


    # ___________________________________________________________________________
    #
    # TODO: make hash have a :pivot_key_field that drops the key in as an
    # attribute on each value
    #

    #
    # HashType describes an Avro Map type (which corresponds to a Ruby
    # Hash). HashType is a synonym for HashType.
    #
    # Maps use the type name "map" and support one attribute:
    #
    # * values: the schema of the map's values. Avro Map keys are assumed to be strings.
    #
    # @example, a map from string to long is declared with:
    #
    #     {"type": "map", "values": "long"}
    #
    module HashSchema
      def receive(raw)
        return nil if raw.nil? || (raw == "")
        obj = self.new
        raw.each{|rk,rv| obj[rk] = value_factory.receive(rv) }
        obj
      end

      def to_schema()
        (defined?(super) ? super() : {}).merge({ :type => self.type, :values => self.values })
      end

      class Writer < ::Icss::Meta::NamedSchema::Writer
        field     :values,        Object
        validates :values,        :presence => true
        field     :value_factory, Icss::Meta::TypeFactory
        after_receive{|hsh| self.receive_value_factory(self.values) }

        def self.get_klass_name(schema)
          return if super(schema)
          return unless schema[:values].is_a?(Module) || schema[:values].respond_to?(:to_sym)
          values_type_name = schema[:values].to_s.to_sym
          slug = Icss::Meta::Type.klassname_for(values_type_name).gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
          "HashOf#{slug}"
        end

        def self.receive_schema(schema)
          super(schema, Hash, ::Icss::Meta::HashSchema)
        end
      end
    end # HashSchema

    #
    # Describes an Avro Enum type.
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
    module EnumSchema
      def receive(raw)
        return nil if raw.blank?
        obj = raw.to_sym
        unless self.symbols.include?(obj) then raise ArgumentError, "Cannot receive #{raw}: must be one of #{symbols[0..2].join(',')}#{symbols.length > 3 ? ",..." : ""}" ; end
        obj
      end

      def to_schema()
        { :type => self.type, :name => self.fullname, :symbols => self.symbols }
      end

      class Writer < ::Icss::Meta::NamedSchema::Writer
        field     :symbols, :array,  :items => Symbol, :required => true # , :default => []
        validates :symbols, :presence => true

        def self.receive_schema(schema)
          super(schema, Symbol, ::Icss::Meta::EnumSchema)
        end
      end
    end # EnumSchema

    #
    # Describes an Avro Fixed type.
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
    module FixedSchema
      def receive(raw)
        return nil if raw.blank?
        raise ArgumentError, "Value for this field must be Stringlike" if not (raw.respond_to?(:to_sym))
        obj = raw.to_s
        unless raw.length <= size then raise ArgumentError, "Length of fixed type #{self.fullname} out of bounds: #{raw[0..30]} is too large" ; end
        obj
      end

      def to_schema()
        { :type => self.type, :name => self.fullname, :size => self.size }
      end

      class Writer < ::Icss::Meta::NamedSchema::Writer
        field     :size,    Integer, :validates => { :numericality => { :greater_than => 0 }}
        validates :size,    :numericality => { :greater_than => 0 }

        # retrieve the
        def self.receive_schema(schema)
          super(schema, String, ::Icss::Meta::FixedSchema)
        end
      end
    end # FixedSchema
  end

end
