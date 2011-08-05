module Icss
  class DataAsset
    include Receiver
    include Receiver::ActsAsHash
    include Receiver::ActiveModelShim

    rcvr_accessor :name,      String
    rcvr_accessor :location,  String
    # overriding ruby's deprecated but still present type attr on objects
    attr_accessor :type
    rcvr_accessor :type,      String
    rcvr_accessor :doc,       String

    validates :type, :inclusion => Icss::Type::DERIVED_TYPES.keys.map(&:to_s)

    def named? nm
      name == nm
    end

    def to_hash()
      { :name => name, :location => location, :type => type, :doc => doc }
    end
    def to_json() to_hash.to_json ; end
  end
end
