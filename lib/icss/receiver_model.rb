require 'icss/receiver_model/acts_as_hash'
require 'icss/receiver_model/acts_as_loadable'
require 'icss/receiver_model/acts_as_tuple'
require 'icss/receiver_model/active_model_shim'

module Icss
  module ReceiverModel
    include Gorillib::Hashlike
    include Icss::ReceiverModel::ActsAsHash
    include Gorillib::Hashlike::TreeMerge

    # put all the things in ClassMethods at class level
    def self.included base
      base.class_eval do
        include Icss::ReceiverModel::ActiveModelShim
        include Icss::ReceiverModel::ActsAsLoadable
        include Icss::Meta::RecordModel
      end
    end

  end
end
