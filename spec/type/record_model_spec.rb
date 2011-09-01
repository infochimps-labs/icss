require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'gorillib/object/try_dup'
require 'icss/receiver_model/acts_as_hash'
require 'icss/receiver_model/active_model_shim'
require 'icss/type'                   #
require 'icss/type/simple_types'      # Boolean, Integer, ...
require 'icss/type/named_type'        # class methods for a named type: .metamodel .doc, .fullname, &c
require 'icss/type/record_type'       # class methods for a record model: .field, .receive,
require 'icss/type/record_model'      # instance methods for a record model
#
require 'icss/type/type_factory'      #
require 'icss/type/structured_schema'
require 'icss/type/record_schema'
require 'icss/type/record_field'

require ENV.root_path('spec/support/icss_test_helper')
include IcssTestHelper

describe Icss::Meta::RecordModel do

  before(:each) do
    IcssTestHelper.remove_icss_constants('Poppa', 'Brainy', 'Smurfette', 'Hefty', 'Glad')
    module Icss
      class Poppa < Icss::SmurfRecord
        field :smurfiness, Integer
      end
      module Brainy
        include Icss::Meta::RecordModel
        field :has_glasses, Boolean
      end
      class Smurfette < Poppa
        include Brainy
        field :blondness, Integer
      end
      class Hefty < Icss::SmurfRecord
      end
      class Glad  < Hefty
      end
    end
  end

  let(:poppa     ){ Icss::Poppa.new() }
  let(:smurfette ){ Icss::Smurfette.new() }

  context '#receive!' do
    it 'sets values' do
      smurfette.receive!({ :smurfiness => '98', :blondness => 12.7 })
      smurfette.smurfiness.should == 98
      smurfette.blondness.should == 12
    end
    it 'handles values with #receive_foo methods' do
      smurfette.should_receive(:receive_smurfiness).with('99')
      smurfette.receive!({ :smurfiness => '99' })
    end
    it 'which goes through _set_field_val' do
      smurfette.should_receive(:_set_field_val).with(:smurfiness, 100)
      smurfette.receive!({ :smurfiness => '100' })
    end
    it 'sends to field type klass .receive method' do
      dummy = mock
      foo_type = Class.new
      Icss::Poppa.field :foo, foo_type
      #
      foo_type.should_receive(:receive).with(dummy)
      Icss::Poppa.receive({ :foo => dummy })
    end
  end

  context 'decorates instances' do
    it 'with accessors and receivers' do
      [:smurfiness, :has_glasses, :blondness].each do |f|
        smurfette.should respond_to(f)
        smurfette.should respond_to("#{f}=")
      end
      smurfette.should respond_to(:receive_smurfiness)
      smurfette.should respond_to(:receive_blondness)
      smurfette.blondness.should == nil
       smurfette.blondness = 77
      smurfette.blondness.should == 77
      smurfette.receive_blondness(99)
      smurfette.blondness.should == 99
    end
  end

  context '.after_receive' do
    it 'adds an after_receiver' do
      blk = lambda{ 1 }
      Icss::Poppa.after_receive(:foo, &blk)
      Icss::Poppa.after_receivers[:foo].should == blk
    end
  end

  context '.after_receivers' do
    it 'is run after receive' do
      dummy = mock ; hsh = { :smurfiness => 9 }
      Icss::Poppa.after_receive(:howdy){|hsh| dummy.hello("hello!", smurfiness) }
      dummy.should_receive(:hello).with("hello!", 9)
      Icss::Poppa.receive(hsh)
    end
    it 'gets received hash as args' do
      dummy = mock ; hsh = { :smurfiness => 10 }
      Icss::Poppa.after_receive(:howdy){|hsh| dummy.hello("hello!", hsh) }
      dummy.should_receive(:hello).with("hello!", hsh)
      Icss::Poppa.receive(hsh)
    end
  end

  context '.rcvr_remaining' do
    it 'adds a new field' do
      Icss::Poppa.rcvr_remaining(:bob)
      Icss::Poppa.field_names.should == [:smurfiness, :bob]
      Icss::Poppa.field_named(:bob)[:type].to_s.should == 'Icss::HashOfMetaDotIdenticalFactory'
    end
    it 'receives leftover attrs' do
      Icss::Poppa.rcvr_remaining(:bob)
      obj = Icss::Poppa.receive(:smurfiness => 12, :bogosity => 97)
      obj.bob.should == {:bogosity => 97}
    end
    it 'applies schema to leftover attrs' do
      Icss::Poppa.rcvr_remaining(:bob, :values => :int)
      obj = Icss::Poppa.receive({:smurfiness => 12, :bogosity => "11", :converts => 31.2})
      obj.bob.should == {:bogosity => 11, :converts => 31}
    end
    it 'is {} when no leftover attrs' do
      Icss::Poppa.rcvr_remaining(:bob)
      obj = Icss::Poppa.receive({:smurfiness => 12})
      obj.bob.should == {}
      obj = Icss::Poppa.receive({})
      obj.bob.should == {}
    end
  end

  context ':default =>' do
    before do
      Icss::Hefty.field :tool,    Symbol, :default => :pipesmurf
      Icss::Hefty.field :weapon,  Symbol, :default => :smurfthrower
      Icss::Hefty.field :no_default, Symbol
    end
    let(:hefty_smurf){  Icss::Hefty.receive({ :tool => :smurfwrench }) }
    let(:glad_smurf ){  Icss::Glad.receive({  :tool => :smurfwrench }) }

    it 'sets default' do
      hefty_smurf.tool.should   == :smurfwrench
      hefty_smurf.weapon.should == :smurfthrower
      hefty_smurf.no_default.should be_nil
      hefty_smurf.attr_set?(:no_default).should be_false
    end

    it 'does not set default if explicitly nil' do
      hefty_smurf = Icss::Hefty.receive({ :tool => :smurfwrench, :weapon => nil })
      hefty_smurf.weapon.should == nil
      hefty_smurf.attr_set?(:weapon).should be_true
    end

    it 'uses an after_receiver with a predictable name' do
      Icss::Hefty.after_receivers[:default_tool].should be_a(Proc)
    end

    it 'is overridable' do
      proc_before = Icss::Hefty.after_receivers[:default_weapon]
      Icss::Hefty.field :weapon, Symbol, :default => :flamesmurf
      Icss::Hefty.after_receivers[:default_weapon].should_not == proc_before
      hefty_smurf.weapon.should == :flamesmurf
    end

    it 'is overridable in subclass without affecting parent' do
      hefty_proc = Icss::Hefty.after_receivers[:default_weapon]
      Icss::Glad.field :weapon, Symbol, :default => :flamesmurf
      Icss::Hefty.after_receivers[:default_weapon].should     == hefty_proc
      Icss::Glad.after_receivers[ :default_weapon].should_not == hefty_proc
      hefty_smurf.weapon.should == :smurfthrower
      glad_smurf.weapon.should  == :flamesmurf
    end

    it 'try_dups the object when setting default' do
      smurfed_cheese = mock
      Icss::Hefty.field :food, Symbol, :default => smurfed_cheese
      smurfed_cheese.should_receive(:try_dup).with()
      hefty_smurf
    end

    it 'accepts a proc' do
      dummy = mock
      Icss::Glad.field :weapon, Symbol, :default => lambda{ [dummy, tool, self] }
      glad_smurf.weapon.should == [dummy, :smurfwrench, glad_smurf]
    end

    context 'can also be set with set_field_default' do
      it 'with a value' do
        dummy = mock
        Icss::Glad.class_eval do
          set_field_default :weapon, :gatlingsmurf
        end
        glad_smurf.weapon.should == :gatlingsmurf
      end
      it 'with a proc' do
        dummy = mock
        Icss::Glad.class_eval do
          set_field_default :weapon, lambda{ [dummy, tool, self] }
        end
        glad_smurf.weapon.should == [dummy, :smurfwrench, glad_smurf]
      end
    end
  end

end
