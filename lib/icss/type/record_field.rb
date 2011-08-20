module Icss
  module Meta

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
      field :aliases,   Array,   :items => Symbol
      field :order,     String
      field :accessor,  Hash
      field :receiver,  Hash
      field :validates, Hash, :values => Object
      attr_reader   :parent
      attr_accessor :is_reference

      ALLOWED_ORDERS = %w[ascending descending ignore].freeze unless defined?(ALLOWED_ORDERS)
      validates :order, :inclusion => { :in => ALLOWED_ORDERS } if respond_to?(:validates)

      after_receive do |hsh|
        # track recursion of type references
        @is_reference = true if hsh['type'].is_a?(String) || hsh['type'].is_a?(Symbol)
      end

      def receive_type(tp)
        if Icss::STRUCTURED_SCHEMAS.include?(tp)
          self.type = tp
        else
          super(tp)
        end
      end

      # is the field a reference to a named type (true), or an inline schema (false)?
      def is_reference?() is_reference ; end

      def order
        @order || 'ascending'
      end
      def order_direction
        case order when 'ascending' then 1 when 'descending' then -1 else 0 ; end
      end

      # def to_hash()
      #   super.merge({ :type => (is_reference? ? type.fullname : type.to_schema) })
      # end
    end

    module RecordType
      #
    protected
      def empty_field_schema
        RecordField.new
      end
    end
  end
end
