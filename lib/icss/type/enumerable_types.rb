module Icss
  module Type

    Icss::Type::ENUMERABLE_TYPES = {
      :array   => ArrayType,
      :map     => MapType,
      :union   => UnionType,
    }.freeze unless defined?(Icss::Type::ENUMERABLE_TYPES)
  end
end
