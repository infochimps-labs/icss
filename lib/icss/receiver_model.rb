module Icss
  module ReceiverModel
    include Gorillib::Hashlike
    include Icss::ReceiverModel::ActsAsHash
    include Gorillib::Hashlike::TreeMerge
    include Icss::ReceiverModel::ActsAsLoadable
    include Icss::Meta::RecordModel
    include Icss::ReceiverModel::ActsAsTuple

    module ClassMethods
      include Icss::Meta::RecordType
      include Icss::ReceiverModel::ActsAsTuple::ClassMethods
    end

    # put all the things in ClassMethods at class level
    def self.included base
      base.class_eval do
        include Icss::ReceiverModel::ActiveModelShim
        extend  Icss::ReceiverModel::ClassMethods
      end
    end

  end
end
