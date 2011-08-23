module Icss
  module Meta

    class NamedSchema
      include Icss::Meta::RecordModel
      include Icss::ReceiverModel::ActsAsHash
      include Gorillib::Hashlike
      field     :fullname, Symbol, :required => true
      rcvr_alias :name, :fullname
      #
      class_attribute :klass_metatypes   ; self.klass_metatypes   = []
      class_attribute :parent_metamodels ; self.parent_metamodels = []

      after_receive(:verify_name) do |hsh|
        warn "** Missing name for #{self}" unless self.fullname.present?
      end
      after_receive(:register) do |hsh|
        Icss::Meta::Type.registry[fullname] = self if fullname.present?
      end

      def attrs_to_inscribe
        self.class.field_names
      end

      def model_klass
        return @model_klass if @model_klass
        @model_klass = Icss::Meta::NamedType.get_model_klass(fullname, parent_klass||Object)
        model_type = @model_klass.singleton_class
        # inscribe attributes
        attrs_to_inscribe.each do |attr|
          val = self.send(attr)
          model_type.class_eval{ define_method(attr){ val } }
        end
        schema_writer = self
        model_type.class_eval{ define_method(:_schema){ schema_writer } }
        # module inclusions
        parent_metamodels.each do |parent_metamodel|
          @model_klass.class_eval{ include parent_metamodel }
        end
        klass_metatypes.each{|mt| @model_klass.extend(mt) }
        @model_klass.metamodel if @model_klass.respond_to?(:metamodel)
        @model_klass
      end
      #
      def self.receive(schema)
        super(schema).model_klass
      end
      def to_hash
        hsh = super
        hsh[:type] = type
        hsh[:name] = hsh.delete(:fullname)
        hsh
      end
    end

    class StructuredSchema < NamedSchema
      class_attribute :parent_klass
      self.klass_metatypes = [::Icss::Meta::NamedType]
    end

    # An array of objects with a specified type.
    module ArrayType
      def receive(raw)
        return nil if raw.nil? || (raw == "")
        self.new( raw.map{|raw_item| raw_item.is_a?(items) ? raw_item : items.receive(raw_item) } )
      end
      def to_schema() _schema.to_hash end
    end
    module ArrayModel
      def to_wire(options={})
        map{|item| item.respond_to?(:to_wire) ? item.to_wire(options) : item }
      end
    end

    # A hash of objects with a specified type.
    module HashType
      def receive(raw)
        return nil if raw.nil? || (raw == "")
        obj = self.new
        raw.each{|rk,rv| obj[rk] = (rv.is_a?(values) ? rv : values.receive(rv)) }
        obj
      end
      def to_schema() _schema.to_hash end
    end

    # A symbol from a pre-chosen set
    module EnumType
      def receive(raw)
        obj = super(raw) or return
        unless self.symbols.include?(obj) then raise ArgumentError, "Cannot receive #{raw}: must be one of #{symbols[0..2].join(',')}#{symbols.length > 3 ? ",..." : ""}" ; end
        obj
      end
      def to_schema() _schema.to_hash end
    end

    # A Fixed-length buffer. The class size specifies the number of bytes per value (required).
    module FixedType
      # Error thrown when a FixedType is given too few/many bytes
      class FixedValueWrongSizeError < ArgumentError ; end
      # accept like a string but enforce (violently) the length constraint
      def receive(raw)
        obj = super(raw) ; return nil if obj.blank?
        unless obj.bytesize == self.size then raise FixedValueWrongSizeError.new("Wrong size for a fixed-length type #{self.fullname}: got #{obj.bytesize}, not #{self.size}") ; end
        obj
      end
      def to_schema() _schema.to_hash end
    end

    # -------------------------------------------------------------------------
    #
    # Container Types (array, map and union)
    #

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
      self.parent_klass       = Array
      self.klass_metatypes   += [::Icss::Meta::ArrayType]
      self.parent_metamodels += [::Icss::Meta::ArrayModel]
      field :items, Icss::Meta::TypeFactory, :required => true
      #
      after_receive(:register){ true } # don't register
      def fullname
        return @fullname if @fullname
        slug = (Type.klassname_for(items) || object_id.to_s).gsub(/^:*Icss:+/, '').gsub(/:+/, 'Dot')
        @fullname = "ArrayOf#{slug}"
      end
      #
      def self.receive(hsh)
        hsh.symbolize_keys!
        warn "Suspicious key :values - array schema takes :items (#{hsh})" if hsh.has_key?(:values)
        val = super(hsh)
        raise ArgumentError, "Items Factory is no good: #{hsh} - #{val._schema.to_hash}" if val.items.blank?
        val
      end
      def to_hash
        hsh = super
        hsh[:items] = Type.schema_for(items)
        hsh.delete(:name)
        hsh
      end
      def type() :array ; end
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
      self.parent_klass     = Hash
      self.klass_metatypes += [::Icss::Meta::HashType]
      field :values, Icss::Meta::TypeFactory, :required => true
      #
      after_receive(:register){ true } # don't register
      def fullname
        return @fullname if @fullname
        slug = (Type.klassname_for(values) || object_id.to_s).gsub(/^:*Icss:+/, '').gsub(/:+/, 'Dot')
        self.fullname = "HashOf#{slug}"
      end
      #
      def self.receive(hsh)
        hsh.symbolize_keys!
        warn "Suspicious key :items - hash schema takes :values (#{hsh})" if hsh.has_key?(:items)
        val = super(hsh)
        raise ArgumentError, "Value Factory is no good: #{hsh} - #{val._schema}" if val.values.blank?
        val
      end
      def to_hash
        hsh = super
        hsh[:values] = Type.schema_for(values)
        hsh.delete(:name)
        hsh
      end
      def type() :map ; end
    end # HashSchema

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
      self.parent_klass     = Symbol
      self.klass_metatypes += [::Icss::Meta::EnumType]
      field      :symbols, Array,  :items => Symbol, :required => true
      def type() :enum ; end
    end # EnumSchema

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
      self.parent_klass     = String
      self.klass_metatypes += [::Icss::Meta::FixedType]
      field     :size,    Integer, :validates => { :numericality => { :greater_than => 0 }}
      def type() :fixed ; end
    end # FixedSchema

    #
    # Description of a simple type (derived from one of the base classes)
    #
    # Simple uses the type name "simple" and supports the attributes:
    #
    # * name: a string naming this fixed (required).
    # * namespace, a string that qualifies the name;
    #
    class SimpleSchema < ::Icss::Meta::NamedSchema
      field :fullname,         Symbol, :required => true
      field :is_a,             Array, :default => [], :items => Icss::Meta::TypeFactory
      field :doc,              String, :required => true
      rcvr_alias :name, :fullname
      self.klass_metatypes = [::Icss::Meta::NamedType]
      def type() :simple ; end
      #
      def parent_klass()      is_a.first ; end
      def parent_metamodels()
        return [] if is_a.length <= 1
        is_a[1 .. -1].map{|pk| pk.metamodel if pk.respond_to?(:metamodel) }.compact
      end
    end # SimpleSchema

  end
end
