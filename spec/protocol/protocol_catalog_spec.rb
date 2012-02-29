require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss'

describe Icss::Meta::Protocol do
  before do
    Icss::Meta::Protocol.send :flush_registry
    Icss::Meta::Protocol._catalog_loaded = true #prevent automatic loading of catalog
  end
  let(:protocol){ Icss::Meta::Protocol.receive(:protocol => 'test', :namespace => 'name.space') }
  
  # Calling receive adds protocol to registry with after_receiver
  describe :registry do
    specify { Icss::Meta::Protocol.registry.should include('name.space.test' => protocol) }
  end
  
  describe '#find' do
    context 'specific protocol name parameters' do
      before { protocol } # load protocol into registry
      it('return protocol'){ Icss::Meta::Protocol.find('name.space.test').should == protocol }
      it('should error if not found'){ lambda{ Icss::Meta::Protocol.find('name.space.not.found') }.should raise_error(Icss::NotFoundError) }
      it('should error for wildcard name'){ lambda{ Icss::Meta::Protocol.find('name.*.test') }.should raise_error(Icss::NotFoundError) }
    end
    
    context 'wildcard protocol name parameters' do
      before { protocol } # load protocol into registry
      context ':all' do
        it('accepts wilcard names'){ Icss::Meta::Protocol.find(:all, 'name.*').should == [protocol] }
        it('returns empty array if not found'){ Icss::Meta::Protocol.find(:all, 'not.*.found').should == [] }
      end
      
      context ':first' do
        it('accepts wilcard names'){ Icss::Meta::Protocol.find(:first, 'name.*').should == protocol }
        it('returns nil if not found'){ Icss::Meta::Protocol.find(:first, 'not.*.found').should be_nil }
      end
      
      context ':last' do
        it('accepts wilcard names'){ Icss::Meta::Protocol.find(:last, 'name.*').should == protocol }
        it('returns nil if not found'){ Icss::Meta::Protocol.find(:last, 'not.*.found').should be_nil }
      end
    end
  end
  describe '#all, #first, #last' do 
    before { protocol } # load protocol into registry
    it('#all returns all protocols'){ Icss::Meta::Protocol.all.should == [protocol] }
    it('#first returns first of all protocols'){ Icss::Meta::Protocol.first.should == protocol }
    it('#last returns last of all protocols'){ Icss::Meta::Protocol.last.should == protocol }
  end
end