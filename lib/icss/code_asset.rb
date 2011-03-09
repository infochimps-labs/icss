module Icss
  class CodeAsset
    include Receiver
    include Receiver::ActsAsHash

    rcvr_accessor :name,      String
    rcvr_accessor :location,  String

    def to_hash()
      { :name => name, :location => location}
    end

    def to_json() to_hash.to_json ; end

  end
end
