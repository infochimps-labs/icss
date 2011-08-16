require 'icss/receiver_model/acts_as_hash'
require 'icss/receiver_model/acts_as_loadable'
require 'icss/type/acts_as_tuple'
require 'icss/receiver_model/active_model_shim'

module Icss
  module ReceiverModel

    # put all the things in ClassMethods at class level
    def self.included base
      base.class_eval do
        include Icss::Meta::RecordType
        include Icss::ReceiverModel::ActsAsHash
        include Icss::ReceiverModel::ActsAsLoadable
        # include Icss::ReceiverModel::ActiveModelShim
        include Gorillib::Hashlike
        include Gorillib::Hashlike::TreeMerge
      end
    end


    # true if the attr is a receiver variable and it has been set
    def attr_set?(attr)
      self.class.fields.has_key?(attr) && self.instance_variable_defined?("@#{attr}")
    end

    def unset!(attr)
      self.send(:remove_instance_variable, "@#{attr}") if self.instance_variable_defined?("@#{attr}")
    end
    protected :unset!

  end


  class Entity
    include ::Icss::ReceiverModel
    include ::Icss::ReceiverModel::ActsAsTuple
  end

end
