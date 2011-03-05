module Icss
  class Protocol
    include Receiver

    rcvr :name,        String
    rcvr :namespace,   String
    rcvr :types,       Array, :of => Icss::TypeFactory
    rcvr :messages,    Hash,  :of => Icss::Message
    rcvr :data_assets, Array, :of => Icss::DataAsset
    rcvr :targets,     Hash,  :of => Icss::Target
    rcvr :doc,         String
    # attr_accessor :body
    def after_receive hsh
      self.name ||= hsh['protocol']
      # self.body = hsh
      (self.messages||={}).each{|msg_name, msg| msg.protocol = self; msg.name ||= msg_name }
    end

    def path
      fullname.gsub('.','/')
    end
    
    # def initialize(path, protocol_hash)
    #   @dirname   = File.dirname(path)
    #   receive! protocol_hash # .to_mash
    # end

    def receive_targets hsh
      hsh.each!
    end

  end
end
