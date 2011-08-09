module Icss
  module Meta

    module TypeFactory
      def self.receive(*args)
        super(*args)
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
      def receive(raw_items)
        return nil if raw_items.nil? || (raw_items == "")
        self.new( raw_items.map{|raw_item| item_factory.receive(raw_item) } )
      end

      def to_schema()
        (defined?(super) ? super() : {}).merge({ :type => self.type, :items => self.items })
      end

      class Writer
        extend Icss::Meta::NamedSchema
        include Icss::Meta::RecordType
        include Icss::ReceiverModel::ActiveModelShim

        field :type,         Symbol, :validates => { :format => { :with => /^array$/ } }
        field :items,        Object
        field :item_factory, Icss::Meta::TypeFactory
        after_receive{|hsh| self.receive_item_factory(self.items) }

        validates :type,  :presence => true, :format => { :with => /^array$/ }
        validates :items, :presence => true

        def self.name_for_klass(schema)
          return unless schema[:items].respond_to?(:to_sym)
          items_slug = Icss::Meta::Type.klassname_for(schema[:items].to_sym).gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
          "ArrayOf#{items_slug}"
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

    # #
    # # HashType describes an Avro Map type (which corresponds to a Ruby
    # # Hash). HashType is a synonym for HashType.
    # #
    # # Maps use the type name "map" and support one attribute:
    # #
    # # * values: the schema of the map's values. Avro Map keys are assumed to be strings.
    # #
    # # @example, a map from string to long is declared with:
    # #
    # #     {"type": "map", "values": "long"}
    # #
    # module HashType
    #   module Schema
    #     include Icss::Meta::Type::Schema
    #     has_field_writers
    #     def to_schema() super.merge({ :type => :map, :values => self.values })  end
    #     #
    #     field :type,   String, :validates => { :format => { :with => /^map$/ } }
    #     field :values, Object # Icss::Meta::TypeFactory, :required => true
    #   end
    #   def self.included(base) base.extend(Schema) end
    #   #
    #   def self.receive(schema)
    #     schema.symbolize_keys!
    #     klass = make_klass(schema)
    #     klass.class_eval{ include(::Icss::Meta::HashType) }
    #     klass.receive_type   schema[:type]
    #     klass.receive_values schema[:values]
    #     # warn "Illegal type '#{type}' in #{self} schema: should be 'map'" unless (type && (type.to_sym == :map))
    #     klass
    #   end
    #   #
    #   def self.make_klass(schema)
    #     if schema[:values].respond_to?(:to_sym) then
    #       type_appendage = Icss::Meta::Type.klassname_for(schema[:values].to_sym).gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
    #       klass = Icss::Meta::NamedSchema.get_type_klass([], "HashOf#{type_appendage}", Hash)
    #     else
    #       klass = Class.new(Hash)
    #     end
    #   end
    #   #
    #   def initialize(*args, &block)
    #     if args.length == 1 && args.first.respond_to?(:each_pair)
    #       hsh = args.pop
    #     end
    #     super(*args, &block)
    #     self.merge!(hsh) if hsh
    #   end
    # end

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
    # unless defined?(CONTAINER_TYPES)
    #   ::Icss::CONTAINER_TYPES = {
    #     :map     => Icss::HashType,
    #     :array   => Icss::ArraySchema,
    #     :union   => Icss::UnionType,
    #   }.freeze
    # end

    # module ErrorType
    #   include RecordType
    # end

    # #
    # def doc() "" end
    # def doc=(str)
    #   singleton_class.class_eval do
    #     remove_possible_method(:doc)
    #     define_method(:doc){ str }
    #   end
    # end

    # module EnumType
    #   include Icss::Meta::NamedSchema
    #   extend Icss::Meta::RecordType::FieldDecorators
    #   field :symbols, Array, :of => String, :required => true, :default => []
    #   def to_schema
    #     (defined?(super) ? super : {}).merge({ :symbols   => symbols })
    #   end
    # end

    # #
    # # Describes an Avro Enum type.
    # #
    # # Enums use the type name "enum" and support the following attributes:
    # #
    # # name:       a string providing the name of the enum (required).
    # # namespace:  a string that qualifies the name;
    # # doc:        a string providing documentation to the user of this schema (optional).
    # # symbols:    an array, listing symbols, as strings or ruby symbols (required). All
    # #             symbols in an enum must be unique; duplicates are prohibited.
    # #
    # # For example, playing card suits might be defined with:
    # #
    # # { "type": "enum",
    # #   "name": "Suit",
    # #   "symbols" : ["SPADES", "HEARTS", "DIAMONDS", "CLUBS"]
    # # }
    # #
    # class EnumType
    #   module Schema
    #     include Icss::Meta::Type::Schema
    #     include Icss::Meta::NamedSchema::Schema
    #     has_field_writers
    #     field :type,  String, :validates => { :format => { :with => /^array$/ } }
    #     field :symbols, Array, :of => Symbol, :required => true, :default => []
    #     #
    #     def to_schema() super.merge({ :type => :array, :symbols   => symbols }) ; end
    #   end
    #   def self.included(base) base.extend(Schema) end
    #   #
    #   def self.receive(schema)
    #     schema.symbolize_keys!
    #     klass = Icss::Meta::NamedSchema.get_type_klass([], type[:name], Icss::SymbolType)
    #     klass.class_eval{ include(::Icss::Meta::EnumType) }
    #     klass.receive_type    schema[:type]
    #     klass.receive_symbols schema[:symbols]
    #     # warn "Illegal type '#{type}' in #{self} schema: should be 'enum'" unless (type && (type.to_sym == :enum))
    #     klass
    #   end
    # end

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


    #   module ::Icss::Meta::DurationSchema   ; def to_schema() :duration   ; end ; end
    # class Duration   < ::Object  ; self.extend ::Icss::Meta::DurationSchema  ; end

    # unless defined?(NAMED_TYPES)
    #   ::Icss::NAMED_TYPES      = {
    #     :fixed   => Icss::FixedType,
    #     :enum    => Icss::EnumType,
    #     :record  => Icss::RecordType,
    #     :error   => Icss::ErrorType
    #   }.freeze
    # end
  end

end
