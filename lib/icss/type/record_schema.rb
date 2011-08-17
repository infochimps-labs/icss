module Icss
  module Meta

    # class RecordField
    #   include Icss::Meta::RecordModel
    #   include Icss::ReceiverModel::ActsAsHash
    #   include Gorillib::Hashlike
    #   include Gorillib::Hashlike::Keys
    #   remove_possible_method(:type)
    #
    #   field :name,      Symbol,                  :required => true
    #   field :type,      Icss::Meta::TypeFactory, :required => true
    #   field :doc,       String
    #   field :default,   Object
    #   field :required,  Boolean
    #   field :aliases,   :array, :items => String
    #   field :order,     String
    #   field :accessor,  Hash
    #   field :receiver,  Hash
    #   field :validates, Hash
    #   attr_reader   :parent
    #   attr_accessor :is_reference
    #
    #   # is the field a reference to a named type (true), or an inline schema (false)?
    #   def is_reference?() is_reference ; end
    #
    #   ALLOWED_ORDERS = %w[ascending descending ignore].freeze unless defined?(ALLOWED_ORDERS)
    #   def order
    #     @order || 'ascending'
    #   end
    #   def order_direction
    #     case order when 'ascending' then 1 when 'descending' then -1 else 0 ; end
    #   end
    # end


    class RecordSchema
      include Icss::Meta::RecordModel
      include Icss::ReceiverModel::ActsAsHash
      include Gorillib::Hashlike
      include Gorillib::Hashlike::TreeMerge
      field :fullname,         Symbol, :required => true
      field :type,             Symbol, :required => true
      field :is_a,             :array, :default => [], :items => Icss::Meta::TypeFactory
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
        #
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

      def inscribe_is_a(model_klass)

      end
    end


    class ErrorSchema
      include Icss::Meta::RecordType
    end
    module ErrorModel
    end

  end
end
