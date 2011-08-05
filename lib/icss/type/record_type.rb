module Icss
  module Type

    module RecordType

      def self.included(base)
        base.extend(Icss::Type::NamedType)
        base.extend(Icss::Type::RecordType::FieldDecorators)
        base.extend(Icss::Type::RecordType::ReceiverDecorators)
      end
    end

  end
end
