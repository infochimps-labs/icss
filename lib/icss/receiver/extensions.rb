module Receiver

  module ActsAsHash
    def to_hash
      self.class.receiver_attr_names.inject({}) do |h,name|
        val = self.send(name)
        h[name] = (val.respond_to?(:to_hash) ? val.to_hash : val) if val
        h
      end
    end
  end


end
