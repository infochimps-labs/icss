require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/simple_types'
require 'icss/type/named_type'
require 'icss/type/record_type'

module Icss::Smurf
  class Base
    extend Icss::Meta::RecordType
    field :smurfiness, Integer
  end
  class Poppa < Base
  end
  module Brainy
    extend Icss::Meta::RecordType
    field :doing_it, Boolean
  end
  class Smurfette < Poppa
    include Brainy
    field :blondness, Integer
  end
end

describe Icss::Meta::RecordType do
  let(:new_smurf_klass){ k = Class.new(Icss::Smurf::Poppa)  }
  let(:module_smurf   ){ m = Module.new; m.send(:extend, Icss::Meta::RecordType) ; m }
  let(:poppa          ){ Icss::Smurf::Poppa.new() }
  let(:smurfette      ){ Icss::Smurf::Smurfette.new() }

  context '.field' do
    it 'adds field names' do
      Icss::Smurf::Base.field_names.should == [:smurfiness]
    end
    it 'adds field info' do
      Icss::Smurf::Base.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
    end
    it 'inherits parent fields' do
      new_smurf_klass.field(:birthday, Date)
      Icss::Smurf::Poppa.field_names.should == [:smurfiness]
      Icss::Smurf::Poppa.fields.keys.should == [:smurfiness]
      Icss::Smurf::Poppa.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
      new_smurf_klass.field_names.should == [:smurfiness, :birthday]
      new_smurf_klass.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
      new_smurf_klass.fields[:birthday  ].to_hash.should == {:name => :birthday,   :type => Date}
    end
    it 'sets accessor visibility' do
      new_smurf_klass.field(:field_1, Integer, :accessor => :none)
      new_smurf_klass.field(:field_2, Integer, :accessor => :private)
      new_smurf_klass.field(:field_3, Integer, :accessor => :protected)
      new_smurf = new_smurf_klass.new
      new_smurf.should_not respond_to('field_1=')
      new_smurf.should_not respond_to('field_1')
      lambda{ new_smurf.field_2 = :hi }.should raise_error(NoMethodError, /private method \`field_2=/)
      lambda{ new_smurf.field_2       }.should raise_error(NoMethodError, /private method \`field_2/)
      lambda{ new_smurf.field_3 = :yo }.should raise_error(NoMethodError, /protected method \`field_3=/)
      lambda{ new_smurf.field_3       }.should raise_error(NoMethodError, /protected method \`field_3/)
    end
    it 'adds few methods' do
      (Icss::Smurf::Smurfette.public_methods - Class.public_methods).sort.should == [
        :after_receive, :after_receivers,
        :field, :field_names, :fields,
        :metamodel, :to_schema,
        :fullname, :namespace, :basename, :doc, :doc=,
        :rcvr, :rcvr_remaining, :receive,
      ].sort
    end
    it 'adds few methods' do
      (Icss::Smurf::Smurfette.new.public_methods -
        Object.public_methods -
        [ :attr_set?, :receive!, ] # maybe added later by record_model, they're OK
        ).sort.should == [
        :blondness, :blondness=, :doing_it, :doing_it=,
        :receive_blondness,:receive_doing_it,
        :receive_smurfiness, :smurfiness, :smurfiness=,
      ].sort
    end
  end

  context '.fields' do
    it 'inheritance works without weirdness' do
      Icss::Smurf::Poppa.field_names.should     == [:smurfiness]
      Icss::Smurf::Smurfette.field_names.should == [:smurfiness, :doing_it, :blondness]
      Icss::Smurf::Brainy.field_names.should    == [:doing_it]
    end
    #
    it 'fields dynamically added to superclasses appear, in order of ancestry' do
      new_smurf_klass.send(:include, module_smurf)
      module_smurf.field_names.should == []
      new_smurf_klass.field_names.should    == [:smurfiness]
      #
      module_smurf.field(:smurfberries, Integer)
      new_smurf_klass.field_names.should    == [:smurfiness, :smurfberries]
      #
      new_smurf_klass.field(:singing, Boolean)
      module_smurf.field(:smurfberry_crunch, Integer)
      new_smurf_klass.field_names.should    == [:smurfiness, :smurfberries, :smurfberry_crunch, :singing]
    end
    #
    it 're-announcing a field modifies its info hash downstream, but not its order' do
      uncle_smurf = Class.new(Icss::Smurf::Poppa)
      baby_smurf  = Class.new(uncle_smurf)
      baby_smurf.field_names.should == [:smurfiness]
      uncle_smurf.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
      baby_smurf.fields[:smurfiness ].to_hash.should == {:name => :smurfiness, :type => Integer}
      #
      uncle_smurf.field(:smurfiness, Float, :validates => :numericality)
      Icss::Smurf::Poppa.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
      uncle_smurf.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Float, :validates => :numericality}
      baby_smurf.fields[:smurfiness ].to_hash.should == {:name => :smurfiness, :type => Float, :validates => :numericality}
    end
    it 'does not override an existing method' do
      new_smurf_klass.class_eval{ def foo() "hello!" end }
      new_smurf_klass.field :foo, String
      new_smurf_klass.new.foo.should == "hello!"
    end
  end

  context 'class schema' do
    it "has .fullname, .namespace, .basename, and .doc" do
      [:fullname, :namespace, :basename, :doc].each do |meth|
        Icss::Smurf::Smurfette.should         respond_to(meth)
        Icss::Smurf::Smurfette.new.should_not respond_to(meth)
      end
    end
    it "name corresponds to its class & module scope" do
      Icss::Smurf::Smurfette.basename.should  == 'smurfette'
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

  context '.after_receive' do
    it 'needs test'
  end

  context '.rcvr_remaining' do
    it 'needs test'
  end

  context '.receiver_body' do
    it 'needs test'
  end

  context '.receive' do
    it 'needs test'
  end

  context '.add_after_receivers' do
    it 'needs test'
  end

end
