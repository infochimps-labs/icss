require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss'

describe Icss::Meta::Source do
  before do
    Icss::Meta::Source.send :flush_registry
    Icss::Meta::Source._catalog_loaded = true #prevent automatic loading of catalog
  end
  let(:source){ Icss::Meta::Source.receive(:source_id => 'sources.test', :title => 'Test source', :description => 'Source description', :url => 'http://test.com') }
  
  describe '#name' do
    specify { source.name.should == 'test' }
  end
  
  describe '#fullname' do  
    specify { source.fullname.should == 'sources.test' }
  end
  
  
  
  # Calling receive adds source to registry with after_receiver
  describe :registry do
    specify { Icss::Meta::Source.registry.should include('sources.test' => source) }
  end
  
  describe '#find' do
    context 'specific source name parameters' do
      before { source } # load source into registry
      it('return source'){ Icss::Meta::Source.find('sources.test').should == source }
      it('should error if not found'){ lambda{ Icss::Meta::Source.find('sources.not_found') }.should raise_error(Icss::NotFoundError) }
      it('should error for wildcard name'){ lambda{ Icss::Meta::Source.find('sources.*.test') }.should raise_error(Icss::NotFoundError) }
    end
    
    context 'wildcard source name parameters' do
      before { source } # load source into registry
      context ':all' do
        it('accepts wilcard names'){ Icss::Meta::Source.find(:all, 'sources.*').should == [source] }
        it('returns empty array if not found'){ Icss::Meta::Source.find(:all, 'not.*.found').should == [] }
      end
      
      context ':first' do
        it('accepts wilcard names'){ Icss::Meta::Source.find(:first, 'sources.*').should == source }
        it('returns nil if not found'){ Icss::Meta::Source.find(:first, 'not.*.found').should be_nil }
      end
      
      context ':last' do
        it('accepts wilcard names'){ Icss::Meta::Source.find(:last, 'sources.*').should == source }
        it('returns nil if not found'){ Icss::Meta::Source.find(:last, 'not.*.found').should be_nil }
      end
    end
  end
  describe '#all, #first, #last' do 
    before { source } # load source into registry
    it('#all returns all sources'){ Icss::Meta::Source.all.should == [source] }
    it('#first returns first of all sources'){ Icss::Meta::Source.first.should == source }
    it('#last returns last of all sources'){ Icss::Meta::Source.last.should == source }
  end
  
  describe '#to_hash' do
    it { source.to_hash.should == {:source_id => 'sources.test',
                                   :title => 'Test source',
                                   :description => 'Source description',
                                   :url => 'http://test.com'}}
  end
end