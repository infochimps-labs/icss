module Icss
  class CodeAsset
    include Receiver

    rcvr :name,      String
    rcvr :location,  String

    def to_hash()
      { :name => name, :location => location}
    end

    def to_json() to_hash.to_json ; end

  end
end
