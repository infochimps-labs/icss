require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/schema'
require 'icss/type/has_fields'

describe Icss::Meta::Schema do

  module Icss
    module This
      module That
        class TheOther
        end
      end
    end
    Blinken = 7
  end

  context '.make' do
    it 'succeeds when the class already exists' do
      mock_class = mock("does not use superklass")
      klass, meta_module = Icss::Meta::Schema.make('this.that.the_other', mock_class)
      klass.should be_a(Class)
      klass.name.should == 'Icss::This::That::TheOther'
      meta_module.should be_a(Module)
      meta_module.name.should == 'Icss::Meta::This::That::TheOtherType'
    end
    it 'succeeds when the class does not already exist' do
      Icss.should_not be_const_defined(:YourMom)
      klass, meta_module = Icss::Meta::Schema.make('your_mom.wears.combat_boots', Hash)
      klass.name.should == 'Icss::YourMom::Wears::CombatBoots'
      klass.should < Hash
      Icss::Meta::YourMom::Wears::CombatBootsType.class.should == Module
      Icss::Meta::YourMom::Wears.class.should                  == Module
      Icss::YourMom::Wears::CombatBoots.class.should           == Class
      Icss::YourMom::Wears.class.should                        == Module
      Icss::Meta.send(:remove_const, :YourMom)
      Icss.send(:remove_const, :YourMom)
    end
  end

end
