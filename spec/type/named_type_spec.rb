require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/named_type'

describe Icss::Type::NamedType do

  module Icss
    module This
      module That
        class TheOther
        end
      end
    end
    Blinken = 7
  end

  context '.fullname_for' do
    it 'converts from avro-style' do
      Icss::Type::NamedType.fullname_for('a.b.c').should                           == 'a.b.c'
      Icss::Type::NamedType.fullname_for('one_to.tha_three.to_tha_fo').should      == 'one_to.tha_three.to_tha_fo'
    end
    it 'converts from ruby-style' do
      Icss::Type::NamedType.fullname_for('A::B::C').should                         == 'a.b.c'
      Icss::Type::NamedType.fullname_for('OneTo::ThaThree::ToThaFo').should        == 'one_to.tha_three.to_tha_fo'
      Icss::Type::NamedType.fullname_for('Icss::OneTo::ThaThree::ToThaFo').should  == 'one_to.tha_three.to_tha_fo'
    end
  end

  context '.klassname_for' do
    it 'converts from avro-style' do
      Icss::Type::NamedType.klassname_for('a.b.c').should                          == '::Icss::A::B::C'
      Icss::Type::NamedType.klassname_for('one_to.tha_three.to_tha_fo').should     == '::Icss::OneTo::ThaThree::ToThaFo'
    end
    it 'converts from ruby-style' do
      Icss::Type::NamedType.klassname_for('A::B::C').should                        == '::Icss::A::B::C'
      Icss::Type::NamedType.klassname_for('OneTo.ThaThree.ToThaFo').should         == '::Icss::OneTo::ThaThree::ToThaFo'
      Icss::Type::NamedType.klassname_for('Icss::OneTo::ThaThree::ToThaFo').should == '::Icss::OneTo::ThaThree::ToThaFo'
    end
  end


  context '.make' do
    it 'succeeds when the class already exists' do
      klass, meta_module = Icss::Type::NamedType.make('this.that.the_other')
      klass.should be_a(Class)
      klass.name.should == 'Icss::This::That::TheOther'
      meta_module.should be_a(Module)
      meta_module.name.should == 'Icss::Type::This::That::TheOtherType'
    end
    it 'succeeds when the class does not already exist' do
      Icss.should_not be_const_defined(:YourMom)
      klass, meta_module = Icss::Type::NamedType.make('your_mom.wears.combat_boots')
      klass.name.should == 'Icss::YourMom::Wears::CombatBoots'
      Icss::Type::YourMom::Wears::CombatBootsType.class.should == Module
      Icss::Type::YourMom::Wears.class.should                  == Module
      Icss::YourMom::Wears::CombatBoots.class.should           == Class
      Icss::YourMom::Wears.class.should                        == Module
      Icss::Type.send(:remove_const, :YourMom)
      Icss.send(:remove_const, :YourMom)
    end
    it 'includes its meta type as a module' do
      Icss.should_not be_const_defined(:YourMom)
      klass, meta_module = Icss::Type::NamedType.make('your_mom.wears.combat_boots')
      # klass.should < Icss::Type::YourMom::Wears::CombatBootsType
    end
  end

end

