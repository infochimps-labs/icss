require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss'
require ENV.root_path('spec/support/icss_test_helper')
include IcssTestHelper


describe Icss::Meta::MessageSample do
  before(:each) do
    IcssTestHelper.remove_icss_constants('Poppa', 'Smurfette', 'Handy')
    class Icss::Poppa < Icss::SmurfRecord
      field :smurfiness, Integer      
    end
    class Icss::Smurfette < Icss::SmurfRecord
      field :blondness, Integer
    end
    class Icss::Handy < Icss::SmurfRecord
      field :smurfiness, Integer
      field :tool,       Symbol, :default => :smurfwrench
      field :weapon,     Symbol, :default => :smurfthrower
    end
  end

  let(:smurfy_message){
    Icss::Meta::Message.receive({
        :name     => 'dance',
        :request  => { :params => Icss::Poppa },
        :response => Icss::Poppa,
      })
  }

  

  it 'receives' do
    
  end

  it 'constructs a response object' do
    
  end
  
  context 'loading from API'  do
    it 'constructs a URL'
    it 'loads'
    it 'accepts a server'
  end
  
end
