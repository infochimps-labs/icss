require 'icss/receiver_model/acts_as_hash'
require 'icss/receiver_model/acts_as_loadable'
require 'icss/receiver_model/active_model_shim'
require 'icss/receiver_model/validations'
require 'icss/receiver_model/acts_as_tuple'

module Icss
  module ReceiverModel
    include Gorillib::Hashlike
    include Icss::ReceiverModel::ActsAsHash
    include Gorillib::Hashlike::TreeMerge
    include Icss::ReceiverModel::ActsAsLoadable
    include Icss::Meta::RecordModel

    module ClassMethods
      include Icss::Meta::RecordType
    end

    # put all the things in ClassMethods at class level
    def self.included base
      base.class_eval do
        include Icss::ReceiverModel::ActiveModelShim
        extend Icss::ReceiverModel::ClassMethods
      end
    end

  end
end
