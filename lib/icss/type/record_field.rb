module Icss
  module Meta

    class RecordField
      include Icss::Meta::RecordModel
      include Icss::ReceiverModel::ActsAsHash
      include Gorillib::Hashlike
      include Gorillib::Hashlike::Keys
      include Icss::ReceiverModel
      include Icss::ReceiverModel::ActiveModelShim
      remove_possible_method(:type)

      ALLOWED_ORDERS = %w[ascending descending ignore].freeze unless defined?(ALLOWED_ORDERS)

      field :name,       Symbol,                  :required => true
      field :type,       Icss::Meta::TypeFactory, :required => true
      field :doc,        String
      field :default,    Icss::Meta::IdenticalFactory
      field :replace,    Hash
      field :required,   Boolean
      field :aliases,    Array,   :items => Symbol
      field :order,      String,  :validates => { :inclusion => { :in => ALLOWED_ORDERS } }
      field :accessor,   Symbol
      field :receiver,   Symbol
      field :validates,  Hash
      rcvr_remaining :_extra_params
      attr_accessor :parent

      # FIXME: cruft
      field :indexed_on, Symbol
      field :identifier, Boolean, :doc => 'indicates the field is suitable for use'

      after_receive(:warnings) do |hsh|
        # warn "Extra params given to field #{self}: #{_extra_params.inspect}" if _extra_params.present?
        warn "Validation failed for field #{self}: #{errors.inspect}" if respond_to?(:errors) && (not valid?)
      end

      # track recursion of type references
      after_receive(:am_i_a_reference) do |hsh|
        hsh = hsh.symbolize_keys
        nonreference_klasses = [::Icss::Meta::ArrayType, ::Icss::Meta::HashType, ::Icss::Meta::EnumType, ::Icss::Meta::FixedType]

        @is_reference = (hsh[:type].is_a?(String) || hsh[:type].is_a?(Symbol) || (hsh[:type].is_a?(Class) && nonreference_klasses.none?{|klass| hsh[:type].is_a?(klass) }))
      end

      # is the field a reference to a named type (true), or an inline schema (false)?
      def is_reference?() @is_reference ; end

      def to_hash()
        hsh = super
        hsh = hsh.merge({ :type => (is_reference? ? type.fullname : Type.schema_for(type)) })
        hsh.delete(:_extra_params)
        hsh
      end
      def to_schema
        to_hash
      end

      # Hack hack -- makes it so fields go thru the receiver door when merged in RecordType
      def merge(hsh)
        dup.receive!(hsh)
      end

      # Order is defined by the avro spec
      def order()           @order || 'ascending' ; end
      def order_direction() case order when 'ascending' then 1 when 'descending' then -1 else 0 ; end ; end
    end

    module RecordType
    protected
      # create new field_schema as a RecordField object, not Hash
      def make_field_schema
        RecordField.new
      end
    end
  end
end
