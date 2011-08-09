require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/named_schema'
require 'icss/type/has_fields'
require 'icss/type/named_schema'
require 'icss/type/record_type'

module Icss::Smurf
  class Base
    include Icss::Meta::RecordType
    field :smurfiness, Integer
  end
  class Poppa < Base
  end
  module Brainy
    include Icss::Meta::RecordType
    field :doing_it, Boolean
  end
  class Smurfette < Poppa
    include Brainy
    field :blondness, Integer
  end
end

describe Icss::Meta::RecordType do
  let(:new_smurf_klass){ k = Class.new(Icss::Smurf::Poppa)  }
  let(:module_smurf   ){ m = Module.new; m.send(:extend, Icss::Meta::HasFields) ; m }
  let(:poppa          ){ Icss::Smurf::Poppa.new() }
  let(:smurfette      ){ Icss::Smurf::Smurfette.new() }

  context 'class schema' do
    it "has .fullname, .namespace, .typename, and .doc" do
      [:fullname, :namespace, :typename, :doc].each do |meth|
        Icss::Smurf::Smurfette.should         respond_to(meth)
        Icss::Smurf::Smurfette.new.should_not respond_to(meth)
      end
    end
    it "name corresponds to its class & module scope" do
      Icss::Smurf::Smurfette.typename.should  == 'smurfette'
      Icss::Smurf::Smurfette.namespace.should == 'smurf'
      Icss::Smurf::Smurfette.fullname.should  == 'smurf.smurfette'
    end
    it "has a settable doc string" do
      Icss::Smurf::Poppa.doc = "Poppa Doc: be cool with them Haitians"
      Icss::Smurf::Poppa.doc.should     == "Poppa Doc: be cool with them Haitians"
      Icss::Smurf::Smurfette.doc.should == "Poppa Doc: be cool with them Haitians"
      Icss::Smurf::Smurfette.doc        =  "Gentlesmurfs prefer blondes"
      Icss::Smurf::Smurfette.doc.should == "Gentlesmurfs prefer blondes"
      Icss::Smurf::Poppa.doc.should     == "Poppa Doc: be cool with them Haitians"
    end
  end

  context '#receive!' do
    it 'sets values' do
      smurfette.receive!({ :smurfiness => '99', :blondness => 12.7 })
      smurfette.smurfiness.should == 99
      smurfette.blondness.should == 12
    end
    it 'handles values with #receive_foo methods' do
      smurfette.should_receive(:receive_smurfiness).with('99')
      smurfette.receive!({ :smurfiness => '99' })
    end
    it 'which goes through _set_field_val' do
      smurfette.should_receive(:_set_field_val).with(:smurfiness, 99)
      smurfette.receive!({ :smurfiness => '99' })
    end
  end

  context 'decorates instances' do
    it 'with accessors and receivers' do
      [:smurfiness, :doing_it, :blondness].each do |f|
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
end
