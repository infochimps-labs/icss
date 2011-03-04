module Icss
  class DataAsset
    include Receiver
    rcvr :name,      String
    rcvr :location,  String
    rcvr :type,      String
    rcvr :doc,       String

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
