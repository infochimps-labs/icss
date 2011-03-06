module Icss
  class DataAsset
    include Receiver
    rcvr_accessor :name,      String
    rcvr_accessor :location,  String
    rcvr_accessor :type,      String
    rcvr_accessor :doc,       String

    def named? nm
      name == nm
    end

    def type_obj
      Icss::Type.find(type)
    end

    def to_hash()
      { :name => name, :location => request, :type => type, :doc => doc }
    end
    def to_json() to_hash.to_json ; end
  end
end
