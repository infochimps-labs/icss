require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss'

describe Icss::Meta::Type do
  before { Icss::Meta::Type.send :flush_registry }
  Icss::Meta::Type._catalog_loaded = true #prevent automatic loading of catalog
  let(:type){ Icss::Meta::TypeFactory.receive(:name => 'name.space.test', :type => :record) }
  before { Icss::Meta::TypeFactory.receive(:name => 'name.space.test', :type => :record) } # load type into registry
  
  # Calling receive adds type to registry with after_receiver
  describe :registry do
    specify { Icss::Meta::Type.registry.should include('name.space.test' => type) }
  end
  
  describe '#find' do
    context 'specific type name parameters' do
      it('returns the type'){ Icss::Meta::Type.find('name.space.test').should == type }
      it('should error if not found'){ lambda{ Icss::Meta::Type.find('name.space.not.found') }.should raise_error(Icss::NotFoundError) }
      it('should error for wildcard name'){ lambda{ Icss::Meta::Type.find('name.*.test') }.should raise_error(Icss::NotFoundError) }
    end
    
    context 'wildcard type name parameters' do
      context ':all' do
        it('accepts wilcard names'){ Icss::Meta::Type.find(:all, 'name.*').should == [type] }
        it('returns empty array if not found'){ Icss::Meta::Type.find(:all, 'not.*.found').should == [] }
      end
      
      context ':first' do
        it('accepts wilcard names'){ Icss::Meta::Type.find(:first, 'name.*').should == type }
        it('returns nil if not found'){ Icss::Meta::Type.find(:first, 'not.*.found').should be_nil }
      end
      
      context ':last' do
        it('accepts wilcard names'){ Icss::Meta::Type.find(:last, 'name.*').should == type }
        it('returns nil if not found'){ Icss::Meta::Type.find(:last, 'not.*.found').should be_nil }
      end
    end
  end
  describe '#all, #first, #last' do 
    it('#all returns all types'){ Icss::Meta::Type.all.should == [type] }
    it('#first returns first of all types'){ Icss::Meta::Type.first.should == type }
    it('#last returns last of all types'){ Icss::Meta::Type.last.should == type }
  end
end