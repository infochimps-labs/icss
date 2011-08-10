module Icss
  module Meta

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

      class Writer
        extend Icss::Meta::NamedSchema
        include Icss::Meta::RecordType
        include Icss::ReceiverModel::ActiveModelShim
        #
        field :type,         Symbol, :validates => { :format => { :with => /^array$/ } }
        field :items,        Object
        field :item_factory, Icss::Meta::TypeFactory
        after_receive{|hsh| self.receive_item_factory(self.items) }
        #
        validates :type,  :presence => true, :format => { :with => /^array$/ }
        validates :items, :presence => true

        def self.name_for_klass(schema)
          return unless schema[:items].respond_to?(:to_sym)
          slug = Icss::Meta::Type.klassname_for(schema[:items].to_sym).gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
          "ArrayOf#{slug}"
        end

        # retrieve the
        def self.receive_schema(schema)
          schema_obj = self.receive(schema)
          type_klass = Icss::Meta::NamedSchema.get_type_klass( name_for_klass(schema),  Array)
          type_klass.class_eval{ extend(::Icss::Meta::ArraySchema) }
          inscribe_schema(schema_obj, type_klass.singleton_class)
          type_klass
        end
      end
    end

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

      class Writer
        extend Icss::Meta::NamedSchema
        include Icss::Meta::RecordType
        include Icss::ReceiverModel::ActiveModelShim
        #
        field :type,         Symbol, :validates => { :format => { :with => /^map$/ } }
        field :values,        Object
        field :value_factory, Icss::Meta::TypeFactory
        after_receive{|hsh| self.receive_value_factory(self.values) }
        #
        validates :type,  :presence => true, :format => { :with => /^map$/ }
        validates :values, :presence => true

        def self.name_for_klass(schema)
          return unless schema[:values].respond_to?(:to_sym)
          slug = Icss::Meta::Type.klassname_for(schema[:values].to_sym).gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
          "HashOf#{slug}"
        end

        # retrieve the
        def self.receive_schema(schema)
          schema_obj = self.receive(schema)
          type_klass = Icss::Meta::NamedSchema.get_type_klass( name_for_klass(schema),  Hash)
          type_klass.class_eval{ extend(::Icss::Meta::HashSchema) }
          inscribe_schema(schema_obj, type_klass.singleton_class)
          type_klass
        end
      end
    end

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

      class Writer
        extend Icss::Meta::NamedSchema
        include Icss::Meta::RecordType
        include Icss::ReceiverModel::ActiveModelShim
        #
        field :type,         Symbol, :validates => { :format => { :with => /^enum$/ } }
        field :name,         Symbol, :validates => { :format => { :with => /^enum$/ } }
        field :symbols,      Array,  :items => Symbol, :required => true # , :default => []
        validates :type,    :presence => true, :format => { :with => /^enum$/ }
        validates :name,    :presence => true
        validates :symbols, :presence => true

        # retrieve the
        def self.receive_schema(schema)

          # schema[:symbols].map!(&:to_sym)

          schema_obj = self.receive(schema)
          type_klass = Icss::Meta::NamedSchema.get_type_klass( schema[:name], Symbol )
          type_klass.class_eval{ extend(::Icss::Meta::EnumSchema) }
          type_klass.class_eval{ extend(::Icss::Meta::NamedSchema) }
          inscribe_schema(schema_obj, type_klass.singleton_class)
          type_klass
        end
      end
    end

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
    class FixedType < String
      # include Icss::Meta::NamedSchema
      # extend  RecordType::FieldDecorators
      # #
      # field :size, Integer, :required => true
      # def to_schema
      #   (defined?(super) ? super : {}).merge( :size => size )
      # end
    end



    # #
    # # Describes an Avro Union type.
    # #
    # # Unions are represented using JSON arrays. For example, ["string", "null"]
    # # declares a schema which may be either a string or null.
    # #
    # # Unions may not contain more than one schema with the same type, except for
    # # the named types record, fixed and enum. For example, unions containing two
    # # array types or two map types are not permitted, but two types with different
    # # names are permitted. (Names permit efficient resolution when reading and
    # # writing unions.)
    # #
    # # Unions may not immediately contain other unions.
    # #
    # class UnionType
    #   extend Icss::Meta::ContainerType
    #   #
    #   attr_accessor :embedded_types
    #   attr_accessor :declaration_flavors
    #   #
    #   def receive! type_list
    #     self.declaration_flavors = []
    #     self.embedded_types = type_list.map do |schema|
    #       type = TypeFactory.receive(schema)
    #       declaration_flavors << TypeFactory.classify_schema_declaration(schema)
    #       type
    #     end
    #   end
    #   def to_schema
    #     embedded_types.zip(declaration_flavors).map do |t,fl|
    #       [:named_type].include?(fl) ? t.name : t.to_schema
    #     end
    #   end
    # end
    #

    unless defined?(CONTAINER_TYPES)
      ::Icss::CONTAINER_TYPES = {
        :map     => Icss::Meta::HashSchema::Writer,
        :Hash    => Icss::Meta::ArraySchema::Writer,
        :array   => Icss::Meta::ArraySchema::Writer,
        :Array   => Icss::Meta::ArraySchema::Writer,
        # :union   => Icss::UnionType,
      }.freeze
    end

    unless defined?(NAMED_TYPES)
      ::Icss::NAMED_TYPES      = {
        # :fixed   => Icss::Meta::FixedType,
        :enum    => Icss::Meta::EnumSchema,
        # :record  => Icss::Meta::RecordType,
        # :error   => Icss::Meta::ErrorType
      }.freeze
    end

  end
end
