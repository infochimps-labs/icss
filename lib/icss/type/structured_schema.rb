module Icss
  module Meta

    # class NamedSchema
    #   include Icss::Meta::RecordModel
    #   field     :type,     Symbol, :required => true
    #   field     :fullname, Symbol, :required => true
    #   alias_method :receive_name, :receive_fullname
    #
    #   def self.get_klass_name(schema)
    #     schema[:name]
    #   end
    #
    #   # * create a schema writer object.
    #   # * generate a named class to represent the type
    #   # * add class attributes by extending with the provided type module
    #   # * inscribe
    #   #
    #   def self.receive(schema, superklass, metatype)
    #     schema_obj = super(schema)
    #     schema_obj.fullname ||= get_klass_name(schema)
    #     model_klass = Icss::Meta::NamedType.get_model_klass(schema_obj.fullname, superklass)
    #     #
    #     model_klass.class_eval do
    #       extend ::Icss::Meta::NamedType
    #       extend metatype
    #     end
    #     schema_obj.inscribe_schema(model_klass)
    #     model_klass
    #   end
    #
    #   def inscribe_schema(model_klass)
    #     schema_writer = self
    #     model_type = model_klass.singleton_class
    #     model_type.class_eval{ define_method(:_schema){ schema_writer } }
    #     self.class.field_names.each do |attr|
    #       val = self.send(attr)
    #       model_type.class_eval{ define_method(attr){ val } }
    #     end
    #   end
    # end

    # #
    # # Description of an Fixed type.
    # #
    # # Fixed uses the type name "fixed" and supports the attributes:
    # #
    # # * name: a string naming this fixed (required).
    # # * namespace, a string that qualifies the name;
    # # * size: an integer, specifying the number of bytes per value (required).
    # #
    # #   For example, 16-byte quantity may be declared with:
    # #
    # #     {"type": "fixed", "size": 16, "name": "md5"}
    # #
    # class FixedSchema < ::Icss::Meta::NamedSchema
    #   field     :size,    Integer, :validates => { :numericality => { :greater_than => 0 }}
    #   # retrieve the
    #   def self.receive(schema)
    #     super(schema, String, ::Icss::Meta::FixedType)
    #   end
    # end # FixedSchema
    #
    # #
    # # A Fixed type.
    # #
    # # Fixed uses the type name "fixed" and supports the attributes:
    # #
    # # * name: a string naming this fixed (required).
    # # * namespace, a string that qualifies the name;
    # # * size: an integer, specifying the number of bytes per value (required).
    # #
    # #   For example, 16-byte quantity may be declared with:
    # #
    # #     {"type": "fixed", "size": 16, "name": "md5"}
    # #
    # module FixedType
    #   # Error thrown when a FixedType is given too few/many bytes
    #   class FixedValueWrongSizeError < ArgumentError ; end
    #   # accept like a string but enforce (violently) the length constraint
    #   def receive(raw)
    #     obj = super(raw) ; return nil if obj.blank?
    #     unless obj.bytesize == self.size then raise FixedValueWrongSizeError.new("Wrong size for a fixed-length type #{self.fullname}: got #{obj.bytesize}, not #{self.size}") ; end
    #     obj
    #   end
    #   #
    #   def to_schema()
    #     { :type => self.type, :name => self.fullname, :size => self.size }
    #   end
    # end
    #
    # # -------------------------------------------------------------------------
    # #
    # # Container Types (array, map and union)
    # #
    #
    # #
    # # ArraySchema describes an Array type (as opposed to ArrayType, which
    # # implements it)
    # #
    # # Arrays use the type name "array" and support a single attribute:
    # #
    # # * items: the schema of the array's items.
    # #
    # # @example, an array of strings is declared with:
    # #
    # #     {"type": "array", "items": "string"}
    # #
    # class ArraySchema < ::Icss::Meta::NamedSchema
    #   field     :items,        Object, :required => true
    #   field     :item_factory, Icss::Meta::TypeFactory
    #   after_receive{|hsh| self.receive_item_factory(self.items) }
    #   #
    #   def self.get_klass_name(schema)
    #     return if super(schema)
    #     slug = Icss::Meta::Type.klassname_for(schema[:items]) or return
    #     slug = slug.gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
    #     "ArrayOf#{slug}"
    #   end
    #   #
    #   def self.receive(schema)
    #     super(schema, Array, ::Icss::Meta::ArrayType)
    #   end
    # end
    #
    # #
    # # ArrayType provides the behavior an Array type.
    # #
    # # Arrays use the type name "array" and support a single attribute:
    # #
    # # * items: the schema of the array's items.
    # #
    # # @example, an array of strings is declared with:
    # #
    # #     {"type": "array", "items": "string"}
    # #
    # module ArrayType
    #   def receive(raw)
    #     return nil if raw.nil? || (raw == "")
    #     self.new( raw.map{|raw_item| item_factory.receive(raw_item) } )
    #   end
    #   #
    #   def to_schema()
    #     (defined?(super) ? super() : {}).merge({ :type => self.type, :items => self.items })
    #   end
    # end
    #
    # #
    # # HashSchema describes an Avro Map type (which corresponds to a Ruby
    # # Hash).
    # #
    # # Hashes use the type name "hash" (or "map") and support one attribute:
    # #
    # # * values: the schema of the map's values. Avro Map keys are assumed to be strings.
    # #
    # # @example, a map from string to long is declared with:
    # #
    # #     {"type": "map", "values": "long"}
    # #
    # class HashSchema < ::Icss::Meta::NamedSchema
    #   field     :values,        Object, :required => true
    #   field     :value_factory, Icss::Meta::TypeFactory
    #   after_receive{|hsh| self.receive_value_factory(self.values) }
    #   #
    #   def self.get_klass_name(schema)
    #     return if super(schema)
    #     slug = Icss::Meta::Type.klassname_for(schema[:values]) or return
    #     slug = slug.gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
    #     "HashOf#{slug}"
    #   end
    #   #
    #   def self.receive(schema)
    #     super(schema, Hash, ::Icss::Meta::HashType)
    #   end
    # end # HashSchema
    #
    # module HashType
    #   def receive(raw)
    #     return nil if raw.nil? || (raw == "")
    #     obj = self.new
    #     raw.each{|rk,rv| obj[rk] = value_factory.receive(rv) }
    #     obj
    #   end
    #   #
    #   def to_schema()
    #     (defined?(super) ? super() : {}).merge({ :type => self.type, :values => self.values })
    #   end
    # end
    #
    # #
    # # An EnumSchema escribes an Enum type.
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
    # class EnumSchema < ::Icss::Meta::NamedSchema
    #   field     :symbols, :array,  :items => Symbol, :required => true
    #   #
    #   def self.receive(schema)
    #     super(schema, Symbol, ::Icss::Meta::EnumType)
    #   end
    # end # EnumSchema
    # #
    # module EnumType
    #   def receive(raw)
    #     obj = super(raw) or return
    #     unless self.symbols.include?(obj) then raise ArgumentError, "Cannot receive #{raw}: must be one of #{symbols[0..2].join(',')}#{symbols.length > 3 ? ",..." : ""}" ; end
    #     obj
    #   end
    #   #
    #   def to_schema()
    #     { :type => self.type, :name => self.fullname, :symbols => self.symbols }
    #   end
    # end

    class RecordSchema
      include Icss::Meta::RecordModel
      include Icss::ReceiverModel::ActsAsHash
      include Gorillib::Hashlike
      include Gorillib::Hashlike::TreeMerge
      field :fullname,         Symbol, :required => true
      field :type,             Symbol, :required => true
      field :is_a,             Object, :default => [] # :array, :items => Icss::Meta::TypeFactory
      field :_domain_id_field, String, :default => 'name'
      #
      field :doc,              String, :required => true
      field :fields,           Object # :array, :default => [], :items => Object # , :items => Icss::Meta::RecordField
      #
      alias_method :receive_name, :receive_fullname

      def self.get_klass_name(schema)
        schema[:name]
      end

      def self.receive(schema, default_superklass=Object)
        schema_obj = super(schema)
        schema_obj.fullname ||= get_klass_name(schema)
        #
        superklass = schema_obj.is_a.first || default_superklass
        warn "No multiple inheritance yet (sorry, #{schema_obj.fullname})" if schema_obj.is_a.length > 1
        model_klass = Icss::Meta::NamedType.get_model_klass(schema_obj.fullname, superklass)
        #
        model_klass.class_eval do
          include(::Icss::Meta::RecordModel)
        end
        #
        schema_obj.inscribe_schema(model_klass)
        model_klass.metatype
        model_klass
      end

      def inscribe_schema(model_klass)
        schema_writer = self
        model_type = model_klass.singleton_class
        model_type.class_eval{ define_method(:_schema){ schema_writer } }
        #
        [:doc, :fullname, :is_a, :_domain_id_field
        ].each do |attr|
          val = self.send(attr)
          model_type.class_eval{ define_method(attr){ val } }
        end
        inscribe_fields(model_klass)
      end

      def inscribe_fields(model_klass)
        self.fields.each do |field_schema|
          field_schema.symbolize_keys!
          model_klass.field(field_schema[:name], field_schema[:type], field_schema)
        end
      end
    end


    class ErrorSchema
      include Icss::Meta::RecordType
    end
    module ErrorModel
    end

  end
end
