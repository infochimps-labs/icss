module Icss
  class Protocol
    include Receiver

    rcvr_accessor :name,        String
    rcvr_accessor :namespace,   String # must be *dotted* ("foo.bar"), not slashed ("foo/bar")
    rcvr_accessor :types,       Array, :of => Icss::TypeFactory
    rcvr_accessor :messages,    Hash,  :of => Icss::Message
    rcvr_accessor :data_assets, Array, :of => Icss::DataAsset
    rcvr_accessor :doc,         String

    # String: namespace.name
    def fullname
      "#{namespace}.#{name}"
    end


    # attr_accessor :body
    def after_receive hsh
      self.name ||= hsh['protocol']
      # self.body = hsh
      (self.messages||={}).each{|msg_name, msg| msg.protocol = self; msg.name ||= msg_name }
    end

    def initialize(path, protocol_hash)
      @dirname   = File.dirname(path)
      receive! protocol_hash # .to_mash
    end


    def to_hash()
      {
        :name => name, :namespace => namespace, :doc => doc,
        :types => (types||[]).map{|t| t.to_hash }
      }
    end
    # This will cause funny errors when it is an element of something that's to_json'ed
    def to_json() to_hash.to_json ; end
  end
end
