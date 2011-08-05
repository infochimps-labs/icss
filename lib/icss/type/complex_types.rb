module Icss
  module Type

    Icss::Type::NAMED_TYPES      = {
      :fixed   => FixedType,
      :enum    => EnumType,
      :record  => RecordType,
      :error   => ErrorType
    }.freeze unless defined?(Icss::Type::NAMED_TYPES)

  end
end
