module Icss
  module Meta

    module RecordType
      #
      def to_schema
        #(defined?(super) ? super() : {}).merge(
        ({
            :name => fullname,
          :type   => :record,
          :doc    => doc,
          :fields => field_names.map{|fn| fields[fn] },
          :is_a   => _schema.is_a,
         }).compact_blank
      end
    end

    class RecordSchema
      include Icss::Meta::RecordModel
      include Icss::ReceiverModel::ActsAsHash
      include Gorillib::Hashlike
      include Gorillib::Hashlike::TreeMerge
      field :fullname,         Symbol, :required => true
      alias_method :receive_name, :receive_fullname
      field :type,             Symbol, :required => true
      field :is_a,             :array, :default => [], :items => Icss::Meta::TypeFactory
      field :_domain_id_field, String, :default => 'name'
      #
      field :doc,              String, :required => true
      field :fields,           :array, :default => [], :items => Object # , :items => Icss::Meta::RecordField
      attr_accessor :model_klass
      attr_accessor :model_superklass

      def self.get_klass_name(schema)
        schema[:name]
      end

      def self.receive(schema, default_superklass=Object)
        schema_obj = super(schema)
        schema_obj.fullname ||= get_klass_name(schema)
        schema_obj.is_a = [default_superklass] if schema_obj.is_a.empty? && (default_superklass != Object)
        #
        model_klass = Icss::Meta::NamedType.get_model_klass(schema_obj.fullname, (schema_obj.parent_klass||Object))
        #
        model_klass.class_eval do
          include(::Icss::Meta::RecordModel)
        end
        #
        schema_obj.decorate_with_superclass_models(model_klass)
        #
        schema_obj.inscribe_schema(model_klass)
        model_klass
      end

      def parent_klass()      is_a.first ; end
      def parent_metamodels() ( (is_a.length <= 1) ? [] : is_a[1 .. -1].map(&:metamodel) ) ; end

      def decorate_with_superclass_models(model_klass)
        parent_metamodels.each do |parent_metamodel|
          model_klass.class_eval{ include parent_metamodel }
        end
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

      def inscribe_is_a(model_klass)

      end
    end

    class RecordField
      include Icss::Meta::RecordModel
      include Icss::ReceiverModel::ActsAsHash
      include Gorillib::Hashlike
      include Gorillib::Hashlike::Keys
      remove_possible_method(:type)

      field :name,      String,                  :required => true
      field :type,      Icss::Meta::TypeFactory, :required => true
      field :doc,       String
      field :default,   Object
      field :required,  Boolean
      field :aliases,   Array,   :items => String
      field :order,     String
      field :accessor,  Hash
      field :receiver,  Hash
      field :validates, Hash
      attr_reader   :parent
      attr_accessor :is_reference

      after_receive do |hsh|
        # track recursion of type references
        @is_reference = true if hsh['type'].is_a?(String) || hsh['type'].is_a?(Symbol)
      end

      # is the field a reference to a named type (true), or an inline schema (false)?
      def is_reference?() is_reference ; end

      ALLOWED_ORDERS = %w[ascending descending ignore].freeze unless defined?(ALLOWED_ORDERS)
      def order
        @order || 'ascending'
      end
      def order_direction
        case order when 'ascending' then 1 when 'descending' then -1 else 0 ; end
      end

      def to_hash()
        super.merge({ :type => (is_reference? ? type.fullname : type.to_schema) })
      end
    end


    class ErrorSchema
      include Icss::Meta::RecordType
    end
    module ErrorModel
    end

  end
end
