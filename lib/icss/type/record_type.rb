module Icss
  module Type

    module RecordType
      def self.included(base)
        p base
        base.extend(Icss::Type::NamedType)
        base.extend(Icss::Type::RecordType::FieldDecorators)
      end
    end

  end
end
