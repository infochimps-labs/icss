require File.expand_path('spec_helper', File.dirname(__FILE__))
require 'icss'
require ENV.root_path('spec/support/icss_test_helper')
include IcssTestHelper

describe Icss::ReceiverModel do
  before do
    IcssTestHelper.remove_icss_constants('Handy', 'UnderHandy')
    class Icss::Handy       < Icss::SmurfModel ; end
    class Icss::UnderHandy  < Icss::Handy ; end
  end

  context 'field validations' do
    before do
      Icss::Handy.field :rangey,     Integer, :validates => { :inclusion => { :in => 0..9 }}
      Icss::Handy.field :mandatory,  Integer, :validates => { :presence  => true }
      Icss::Handy.field :patternish, String,  :validates => { :format    => { :with => /eat$/ } }
    end
    let(:good_smurf){ Icss::Handy.receive(:rangey => 5,  :patternish => 'smurfberry crunch is fun to eat', :mandatory => 1) }
    let(:bad_smurf ){ Icss::Handy.receive(:rangey => 10, :patternish => 'smurfnuggets!') }

    it 'are applied, and pass when good' do
      good_smurf.should be_valid
    end

    it 'are applied, and fail when bad' do
      bad_smurf.should_not be_valid
      bad_smurf.errors.should == {
        :rangey     => ["is not included in the list"],
        :mandatory  => ["can't be blank"],
        :patternish => ["is invalid"]
      }
      bad_smurf.rangey = 3 ; bad_smurf.mandatory = 7 ; bad_smurf.patternish = "a very smurfy breakfast treat"
      bad_smurf.should        be_valid
      bad_smurf.errors.should be_empty
    end

    it 'inherit' do
      under_handy = Icss::UnderHandy.receive(:rangey => -1,  :patternish => 'smurfberry crunch is fun to eat', :mandatory => 1)
      under_handy.should_not be_valid
      under_handy.errors.keys.should == [:rangey]
      under_handy.rangey = 1
      under_handy.should     be_valid
    end

    it ':required => true is sugar for ":validates => { :presence => true }"' do
      Icss::Handy.field :also_mandatory,  Integer, :required => true
      good_smurf.should_not be_valid
      good_smurf.errors.should == { :also_mandatory  => ["can't be blank"], }
      good_smurf.also_mandatory = 88
      good_smurf.should be_valid
    end
  end

  # context ':index => ' do
  #   it 'primary key'
  #   it 'foreign key'
  #   it 'uniqueness constraint'
  # end
  #
  # # context ':accessor / :reader / :writer' do
  # #   it ':private         -- attr_whatever is private'
  # #   it ':protected       -- attr_whatever is protected'
  # #   it ':none            -- no accessor/reader/writer'
  # # end
  #
  # context ':after_receive'
  #
  # context ':i18n_key'
  # context ':human_name => '
  # context ':singular_name => '
  # context ':plural_name => '
  # context ':uncountable => '
  #
  # context :serialization
  # it '#serializable_hash'
  #
  # # constant
  # # mass assignment security: accessible,
  #
  # it 'works on the parent Meta module type, not '
  #
  #
  # context 'has properties' do
  #   it 'described by its #fields'
  #
  #   context 'container types' do
  #
  #     it 'field foo, Array, :items   => FooClass validates instances are is_a?(FooClass)'
  #     it 'field foo, Array, :with => FooFactory validates instances are is_a?(FooFactory.product_klass)'
  #
  #     it ''
  #
  #   end
  # end
  #
  # context 'special properties' do
  #   it '_domain_id_field'
  #   it '_primary_location_field'
  #   it '_slug' # ??
  # end
  #
  # context 'name' do
  #   context ':i18n_key'
  #   context ':human_name => '
  #   context ':singular_name => '
  #   context ':plural_name => '
  #   context ':uncountable => '
  # end

end
