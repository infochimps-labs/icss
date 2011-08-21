require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'gorillib/object/try_dup'
require 'icss/receiver_model/acts_as_hash'
require 'icss/type'                   #
require 'icss/type/simple_types'      # Boolean, Integer, ...
require 'icss/type/named_type'        # class methods for a named type: .metamodel .doc, .fullname, &c
require 'icss/type/record_type'       # class methods for a record model: .field, .receive,
require 'icss/type/record_model'      # instance methods for a record model
#
require 'icss/type/type_factory'      #
require 'icss/type/structured_schema'

module Icss::Smurf
  class Base
    include Icss::Meta::RecordModel
    field :smurfiness, Integer
  end
  class Poppa < Base
  end
  module Brainy
    include Icss::Meta::RecordModel
    field :has_glasses, Boolean
  end
  class Smurfette < Poppa
    include Brainy
    field :blondness, Integer
  end
end

describe Icss::Meta::RecordModel do
  let(:new_smurf_klass){ k = Class.new(Icss::Smurf::Poppa)  }
  let(:poppa          ){ Icss::Smurf::Poppa.new() }
  let(:smurfette      ){ Icss::Smurf::Smurfette.new() }

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
      new_smurf_klass.field :foo, foo_type
      #
      foo_type.should_receive(:receive).with(dummy)
      new_smurf_klass.receive({ :foo => dummy })
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
      proc = lambda{ 1 }
      new_smurf_klass.after_receive(&proc)
      new_smurf_klass.after_receivers.should == [proc]
    end
  end

  context '.after_receivers' do
    it 'is run after receive' do
      dummy = mock ; hsh = { :smurfiness => 9 }
      new_smurf_klass.after_receive{|hsh| dummy.hello("hello!", smurfiness) }
      dummy.should_receive(:hello).with("hello!", 9)
      new_smurf_klass.receive(hsh)
    end
    it 'gets received hash as args' do
      dummy = mock ; hsh = { :smurfiness => 10 }
      new_smurf_klass.after_receive{|hsh| dummy.hello("hello!", hsh) }
      dummy.should_receive(:hello).with("hello!", hsh)
      new_smurf_klass.receive(hsh)
    end
  end

  context '.rcvr_remaining' do
    it 'adds a new field' do
      new_smurf_klass.rcvr_remaining(:bob)
      new_smurf_klass.field_names.should == [:smurfiness, :bob]
      new_smurf_klass.field_named(:bob)[:type].should == Hash
    end
    it 'receives leftover attrs' do
      new_smurf_klass.rcvr_remaining(:bob)
      obj = new_smurf_klass.receive(:smurfiness => 12, :bogosity => 97)
      obj.bob.should == {:bogosity => 97}
    end
    it 'applies schema to leftover attrs' do
      new_smurf_klass.rcvr_remaining(:bob, :values => :int)
      obj = new_smurf_klass.receive(:smurfiness => 12, :bogosity => "11", :converts => 31.2)
      obj.bob.should == {:bogosity => 11, :converts => 31}
    end
    it 'is {} when no leftover attrs' do
      new_smurf_klass.rcvr_remaining(:bob)
      obj = new_smurf_klass.receive({:smurfiness => 12})
      obj.bob.should == {}
      obj = new_smurf_klass.receive({})
      obj.bob.should == {}
    end
  end

end
