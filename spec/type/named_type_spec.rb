require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/named_type'
require 'icss/entity'

describe Icss::Meta::NamedType do

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
      klass, meta_module = Icss::Meta::NamedType.make('this.that.the_other')
      klass.should be_a(Class)
      klass.name.should == 'Icss::This::That::TheOther'
      meta_module.should be_a(Module)
      meta_module.name.should == 'Icss::Meta::This::That::TheOtherType'
    end
    it 'succeeds when the class does not already exist' do
      Icss.should_not be_const_defined(:YourMom)
      klass, meta_module = Icss::Meta::NamedType.make('your_mom.wears.combat_boots')
      klass.name.should == 'Icss::YourMom::Wears::CombatBoots'
      Icss::Meta::YourMom::Wears::CombatBootsType.class.should == Module
      Icss::Meta::YourMom::Wears.class.should                  == Module
      Icss::YourMom::Wears::CombatBoots.class.should           == Class
      Icss::YourMom::Wears.class.should                        == Module
      Icss::Meta.send(:remove_const, :YourMom)
      Icss.send(:remove_const, :YourMom)
    end
    it 'includes its meta type as a module' do
      Icss.should_not be_const_defined(:YourMom)
      klass, meta_module = Icss::Meta::NamedType.make('your_mom.wears.combat_boots')
      # klass.should < Icss::Meta::YourMom::Wears::CombatBootsType
    end
  end

end

