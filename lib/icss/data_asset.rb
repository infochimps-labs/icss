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

    put "fuck you!"
    validates_each :type do |record, attr, value|
      puts value
      record.errors[attr] << "data_asset #{type} must be defined in types:" unless Icss::Type::DERIVED_TYPES.key.include?(value)
    end

    def named? nm
      name == nm
    end

    def to_hash()
      { :name => name, :location => location, :type => type, :doc => doc }
    end
    def to_json() to_hash.to_json ; end
  end
end
