module Icss
  module Meta

    class RecordSchema < SimpleSchema
      include Icss::Meta::RecordModel
      include Icss::ReceiverModel::ActsAsHash
      include Gorillib::Hashlike
      include Gorillib::Hashlike::Keys
      #
      field :_domain_id_field, String,  :default => 'name'
      field :_doc_hints,       Hash,    :default => {}
      field :fields,           Array,   :default => []
      #

      def type() :record ; end

      def to_hash
        {
          :name      => basename,
          :namespace => namespace,
          :type      => type,
          :is_a      => (respond_to?(:is_a) ? is_a : []),
          :doc       => doc,
          :fields    => fields.map(&:to_schema),
         }.compact_blank
      end

      def model_klass
        return @model_klass if @model_klass
        super
        @model_klass.class_eval{ include(::Icss::Meta::RecordModel) }
        self.fields.each do |field_schema|
          @model_klass.field(field_schema[:name], field_schema[:type], field_schema)
        end
        @model_klass
      end

      def receive_fields(flds)
        super(flds.map(&:symbolize_keys!))
      end

      def attrs_to_inscribe
        [ :doc, :fullname, :is_a, :_domain_id_field, :_doc_hints ]
      end
    end

    class ErrorSchema
      include Icss::Meta::RecordType
    end
    module ErrorModel
    end

  end
end
