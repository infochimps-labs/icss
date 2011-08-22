require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss'
require ENV.root_path('spec/support/icss_test_helper')
include IcssTestHelper

describe Icss::Meta::RecordType do
  before do
    IcssTestHelper.remove_icss_constants('Handy')
    class Icss::Handy < Icss::SmurfRecord ; end
  end

  context '.field' do
    it 'with record_field loaded, adds RecordFields not hashes' do
      Icss::Handy.field :foo, Integer
      Icss::Handy.field_named(:foo).should be_a(Icss::Meta::RecordField)
    end

    it 'allows sloppy complex types when I use Hash' do
      Icss::Handy.field :foo, Hash, :values => Integer
      fld = Icss::Handy.field_named(:foo)
      fld.type.to_s.should == 'Icss::HashOfInteger'
      fld.type.values == Integer
    end

    it 'allows sloppy complex types when I use Array' do
      Icss::Handy.field :foo, Array, :items => Integer
      fld = Icss::Handy.field_named(:foo)
      fld.type.to_s.should == 'Icss::ArrayOfInteger'
      fld.type.items == Integer
    end

    it 'does not allow sloppy complex types when I use :hash' do
      lambda{ Icss::Handy.field :bar, :hash, :values => Integer }.should raise_error
    end

    it 'handles complex fields in line' do
      Icss::Handy.field :foo, { :type => :hash, :values => Integer }
      fld = Icss::Handy.field_named(:foo)
      fld.type.to_s.should == 'Icss::HashOfInteger'
      fld.type.values == Integer
    end
  end
end

