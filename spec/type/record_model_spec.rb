require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'                   #
require 'icss/type/simple_types'      # Boolean, Integer, ...
require 'icss/type/named_type'        # class methods for a named type: .metamodel .doc, .fullname, &c
require 'icss/type/record_type'       # class methods for a record model: .field, .receive,
require 'icss/type/record_model'      # instance methods for a record model

module Icss::Smurf
  class Base
    include Icss::Meta::RecordModel
    field :smurfiness, Integer
  end
  class Poppa < Base
  end
  module Brainy
    include Icss::Meta::RecordModel
    field :doing_it, Boolean
  end
  class Smurfette < Poppa
    include Brainy
    field :blondness, Integer
  end
end

describe Icss::Meta::RecordModel do
  let(:new_smurf_klass){ k = Class.new(Icss::Smurf::Poppa)  }
  let(:module_smurf   ){ m = Module.new; m.send(:extend, Icss::Meta::RecordType) ; m }
  let(:poppa          ){ Icss::Smurf::Poppa.new() }
  let(:smurfette      ){ Icss::Smurf::Smurfette.new() }

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
