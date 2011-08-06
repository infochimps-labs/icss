module Icss
  module Meta

    module RecordType
      def self.included(base)
        base.extend(Icss::Meta::NamedType)
        base.extend(Icss::Meta::RecordType::FieldDecorators)
      end
    end

  end
end
