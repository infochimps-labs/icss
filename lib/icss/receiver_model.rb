require 'icss/receiver_model/acts_as_hash'
require 'icss/receiver_model/acts_as_loadable'
require 'icss/receiver_model/acts_as_tuple'
require 'icss/receiver_model/active_model_shim'

module Icss
  module ReceiverModel
    include Icss::Meta::RecordModel

    # put all the things in ClassMethods at class level
    def self.included base
      base.class_eval do
        include Icss::Meta::RecordModel
        include Icss::ReceiverModel::ActsAsHash
        include Icss::ReceiverModel::ActsAsLoadable
        include Gorillib::Hashlike
        include Gorillib::Hashlike::TreeMerge
        include Icss::ReceiverModel::ActiveModelShim
      end
    end

  end
end
