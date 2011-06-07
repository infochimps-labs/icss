require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'icss'

describe Icss do
  [
    Dir[ICSS_ROOT_DIR('examples/hackboxen/**/config.yaml')],
    # Dir[ICSS_ROOT_DIR('examples/apeyeye_endpoints/**/*.icss.yaml')],
  ].flatten[0.. 3].each do |icss_filename|

    describe "loading ICSS file #{icss_filename}" do
      before do
        @icss = Icss::Protocol.receive_from_file(icss_filename)
      end

      # it "serializes out and in again" do
      #   # json_icss = JSON.load(JSON.generate(@icss))
      #   # new_icss = Icss::Protocol.receive(json_icss)
      #   # new_icss.should == @icss
      #   puts JSON.pretty_generate(@icss.to_hash)
      # end

      it "yaml and json are friends" do
        #convert the icss to json and back
        raw_json = JSON.generate(@icss.to_hash.compact)
        json_icss = Icss::Protocol.receive(JSON.parse(raw_json))

        # p @icss.types
        # p @icss.messages
        puts JSON.pretty_generate(@icss.messages.to_hash)

        # #These SHOULD be identical
        # # @icss.messages.should == json_icss.messages
        # json_icss.to_hash.should == @icss.to_hash
      end
    end
  end
end
