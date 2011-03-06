module Icss
  class Message
    include Receiver
    rcvr_accessor :name,     String
    rcvr_accessor :request,  Array, :of => :Hash
    rcvr_accessor :response, Array
    rcvr_accessor :errors,   Array
    rcvr_accessor :doc,      String
    attr_accessor :protocol

    #
    #
    #

    #
    # Sugar
    #

    def response_types
      response.map{|resp| Icss::Type.find(resp) }
    end
    def request_types
      request.map{|req|   Icss::Type.find(req['type']) }
    end

    def path
      File.join(protocol.namespace, protocol.name, self.name)
    end

    #
    # Conversion
    #

    def to_hash()
      { :name => name, :request => request, :response => response, :errors => errors, :doc => doc }
    end
    def to_json() to_hash.to_json ; end
  end
end
