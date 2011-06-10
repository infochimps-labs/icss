require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'icss'


describe Icss::Protocol do
  before do
    @icss = Icss::Protocol.receive_from_file(ICSS_ROOT_DIR('examples/chronic.icss.yaml'))
  end

end
