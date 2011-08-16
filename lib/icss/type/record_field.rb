module Icss
  module Meta

    # class RecordField
    #   include Icss::Meta::RecordType
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

  end
end
