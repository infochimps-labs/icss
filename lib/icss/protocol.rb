module Icss
  class Protocol
    include Receiver

    rcvr :name,        String
    rcvr :namespace,   String
    rcvr :types,       Array, :of => Icss::TypeFactory
    rcvr :messages,    Hash,  :of => Icss::Message
    rcvr :data_assets, Array, :of => Icss::DataAsset
    rcvr :doc,         String
    attr_accessor :body
    def after_receive hsh
      self.name = hsh['protocol']
      self.body = hsh
      messages.each{|msg_name, msg| msg.protocol = self; msg.name ||= msg_name }
    end

    def initialize(path, protocol_hash)
      @dirname   = File.dirname(path)
      receive! protocol_hash.to_mash
    end

    def inspect
      ["#<#{self.class.name}",
        "namespace=#{namespace}",
        "name=#{name}",
        "types=#{(types||[]).map(&:name).inspect}",
        "messages=#{(messages||{}).values.map(&:name).inspect}",
        "data_assets=#{(data_assets||[]).map(&:name).inspect}",
        "doc='#{(doc||"")[0..30]}...'",
        ">"
        ].join(" ")
    end
  end
end
