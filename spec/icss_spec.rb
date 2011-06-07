require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'icss'

describe Icss do
  Dir[ICSS_ROOT_DIR('examples/apeyeye_endpoints/**/*.icss.yaml')][0..6].each do |icss_filename|
    it "loads ICSS file #{icss_filename}" do
      p Icss::Protocol.receive_from_file(icss_filename)
    end
  end
end
