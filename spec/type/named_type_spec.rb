require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/simple_types'
require 'icss/type/named_type'

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
      klass, klass_metamodel = Icss::Meta::NamedType.make('this.that.the_other', Object)
      klass.should be_a(Class)
      klass.name.should == 'Icss::This::That::TheOther'
      klass_metamodel.should be_a(Module)
      klass_metamodel.name.should == 'Icss::Meta::This::That::TheOtherModel'
    end
    it 'succeeds when the class does not already exist' do
      Icss.should_not be_const_defined(:YourMom)
      klass, klass_metamodel = Icss::Meta::NamedType.make('your_mom.wears.combat_boots', Hash)
      klass.name.should == 'Icss::YourMom::Wears::CombatBoots'
      klass.should < Hash
      Icss::Meta::YourMom::Wears::CombatBootsModel.class.should == Module
      Icss::Meta::YourMom::Wears.class.should                  == Module
      Icss::YourMom::Wears::CombatBoots.class.should           == Class
      Icss::YourMom::Wears.class.should                        == Module
      Icss::Meta.send(:remove_const, :YourMom)
      Icss.send(:remove_const, :YourMom)
    end
    it 'creates a klass which inherits (includes) its metatype' do
      klass, klass_metamodel = Icss::Meta::NamedType.make('this.that.the_other', Object)
      klass.metamodel.should == Icss::Meta::This::That::TheOtherModel
    end
  end

  context '.get_nested_module' do
    it 'adds a new child when parents exist' do
      Icss::This::That.should_not be_const_defined(:AlsoThis)
      new_module = Icss::Meta::NamedType.get_nested_module(%w[Icss This That AlsoThis])
      new_module.name.should == 'Icss::This::That::AlsoThis'
      Icss::This::That::AlsoThis.class.should == Module
      Icss::This::That.send(:remove_const, :AlsoThis)
    end
    it 'adds parents as necessary' do
      Icss.should_not be_const_defined(:Winken)
      new_module = Icss::Meta::NamedType.get_nested_module(%w[Icss Winken Blinken Nod])
      new_module.name.should == 'Icss::Winken::Blinken::Nod'
      Icss::Winken::Blinken::Nod.class.should == Module
      Icss::Winken::Blinken.class.should      == Module
      Icss::Winken.class.should               == Module
      Icss.send(:remove_const, :Winken)
    end
  end

 end
