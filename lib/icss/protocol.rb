module Icss
  class Protocol
    include Receiver

    rcvr :name,        String
    rcvr :namespace,   String # must be *dotted* ("foo.bar"), not slashed ("foo/bar")
    rcvr :types,       Array, :of => Icss::TypeFactory
    rcvr :messages,    Hash,  :of => Icss::Message
    rcvr :data_assets, Array, :of => Icss::DataAsset
    rcvr :targets,     Hash,  :of => Icss::TargetListFactory
    rcvr :doc,         String

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

    def path
      fullname.gsub('.','/')
    end
    
    def receive_targets hsh
      self.targets = hsh.inject({}) do |target_obj_hsh, (target_name, target_info_list)|
        target_obj_hsh[target_name] = TargetListFactory.receive(target_name, target_info_list) # returns an arry of targets
        target_obj_hsh
      end
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
