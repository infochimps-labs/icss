require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss'

describe Icss::Meta::License do
  before do
    Icss::Meta::License.send :flush_registry
    Icss::Meta::License._catalog_loaded = true #prevent automatic loading of catalog
  end
  let(:license){ Icss::Meta::License.receive(:license_id => 'licenses.test', :title => 'Test license', :description => 'License description', :url => 'http://test.com', :summary => 'short summer of the license', :article_body => 'full text of license') }
  
  describe '#name' do
    specify { license.name.should == 'test' }
  end
  
  describe '#fullname' do  
    specify { license.fullname.should == 'licenses.test' }
  end
  
  
  
  # Calling receive adds license to registry with after_receiver
  describe :registry do
    specify { Icss::Meta::License.registry.should include('licenses.test' => license) }
  end
  
  describe '#find' do
    context 'specific license name parameters' do
      before { license } # load license into registry
      it('return license'){ Icss::Meta::License.find('licenses.test').should == license }
      it('should error if not found'){ lambda{ Icss::Meta::License.find('licenses.not_found') }.should raise_error(Icss::NotFoundError) }
      it('should error for wildcard name'){ lambda{ Icss::Meta::License.find('licenses.*.test') }.should raise_error(Icss::NotFoundError) }
    end
    
    context 'wildcard license name parameters' do
      before { license } # load license into registry
      context ':all' do
        it('accepts wilcard names'){ Icss::Meta::License.find(:all, 'licenses.*').should == [license] }
        it('returns empty array if not found'){ Icss::Meta::License.find(:all, 'not.*.found').should == [] }
      end
      
      context ':first' do
        it('accepts wilcard names'){ Icss::Meta::License.find(:first, 'licenses.*').should == license }
        it('returns nil if not found'){ Icss::Meta::License.find(:first, 'not.*.found').should be_nil }
      end
      
      context ':last' do
        it('accepts wilcard names'){ Icss::Meta::License.find(:last, 'licenses.*').should == license }
        it('returns nil if not found'){ Icss::Meta::License.find(:last, 'not.*.found').should be_nil }
      end
    end
  end
  describe '#all, #first, #last' do 
    before { license } # load license into registry
    it('#all returns all licenses'){ Icss::Meta::License.all.should == [license] }
    it('#first returns first of all licenses'){ Icss::Meta::License.first.should == license }
    it('#last returns last of all licenses'){ Icss::Meta::License.last.should == license }
  end
  
  describe '#to_hash' do
    it { license.to_hash.should == {:license_id => 'licenses.test',
                                   :title => 'Test license',
                                   :description => 'License description',
                                   :url => 'http://test.com',
                                   :summary => 'short summer of the license',
                                   :article_body => 'full text of license'}}
  end
end