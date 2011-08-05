require 'gorillib/hashlike'
require 'gorillib/hashlike/tree_merge'
require 'icss/receiver_model/acts_as_hash'
require 'icss/receiver_model/acts_as_loadable'
require 'icss/receiver_model/active_model_shim'

module Icss
  module ReceiverModel



    # put all the things in ClassMethods at class level
    def self.included base
      base.class_eval do
        include Icss::ReceiverModel::ActsAsHash
        include Icss::ReceiverModel::ActsAsLoadable
        include Icss::ReceiverModel::ActiveModel
        include Gorillib::Hashlike
        include Gorillib::Hashlike::TreeMerge
      end
    end

  end
end
