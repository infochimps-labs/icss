require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'icss'

describe Icss do
  [
    Dir[ICSS_ROOT_DIR('examples/hackboxen/**/config.yaml')],
    Dir[ICSS_ROOT_DIR('examples/apeyeye_endpoints/**/*.icss.yaml')],
  ].flatten[0.. -1].each do |icss_filename|

    describe "loading ICSS file #{icss_filename}" do
      before do
        @icss = Icss::Protocol.receive_from_file(icss_filename)
      end

      it "serializes out and in again" do
        #convert the icss to json and back
        raw_json = JSON.generate(@icss)
        json_icss = Icss::Protocol.receive(JSON.parse(raw_json))

        json_icss.to_hash.should == @icss.to_hash
      end
    end
  end
end
