require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/named_type'
require 'icss/type/field_decorators'
require 'icss/type/receiver_decorators'
require 'icss/type/record_type'

module Icss::Smurf
  class Base
    include Icss::Type::RecordType
    field :smurfiness, Integer
  end
  class Poppa < Base
  end
  module Brainy
    include Icss::Type::RecordType
    field :doing_it, Boolean
  end
  class Smurfette < Poppa
    include Brainy
    include Icss::Type::RecordType
    field :blondness, Integer
  end
end

class Icss::Type::RecordField
  include Icss::Type::RecordType
  remove_possible_method(:type)
  #
  field :name,      String, :required => true
  field :doc,       String
  field :type,      String, :required => true
  field :default,   Object
  field :required,  Boolean
  field :order,     String
  field :validates, Hash
  attr_reader :parent
end

describe Icss::Type::RecordField do
  context '.receive' do
    it 'works' do
      foo = Icss::Type::RecordField.receive({
          :name => 'height',
          :type => Integer,
          :doc => 'How High',
          :default => 3,
          :required => false,
          :order => 'ascending'
        })
    end
  end
end

describe Icss::Type::RecordType do
  let(:new_smurf_klass){ k = Class.new(Icss::Smurf::Poppa)  }
  let(:poppa          ){ Icss::Smurf::Poppa.new() }
  let(:smurfette      ){ Icss::Smurf::Smurfette.new() }
  let(:module_smurf   ){ m = Module.new; m.send(:include, Icss::Type::RecordType) ; m }

  context 'makes class a NamedType' do
    it "with fullname, namespace, typename, and doc" do
      [:fullname, :namespace, :typename, :doc].each do |meth|
        Icss::Smurf::Smurfette.should         respond_to(meth)
        Icss::Smurf::Smurfette.new.should_not respond_to(meth)
      end
    end
    it "named after its class and containing module" do
      Icss::Smurf::Smurfette.typename.should  == 'smurfette'
      Icss::Smurf::Smurfette.namespace.should == 'smurf'
      Icss::Smurf::Smurfette.fullname.should  == 'smurf.smurfette'
    end
    it "Lets us set the doc field" do
      Icss::Smurf::Poppa.doc = "Poppa Doc: be cool with them Haitians"
      Icss::Smurf::Poppa.doc.should     == "Poppa Doc: be cool with them Haitians"
      Icss::Smurf::Smurfette.doc.should == "Poppa Doc: be cool with them Haitians"
      Icss::Smurf::Smurfette.doc        =  "Gentlesmurfs prefer blondes"
      Icss::Smurf::Smurfette.doc.should == "Gentlesmurfs prefer blondes"
      Icss::Smurf::Poppa.doc.should     == "Poppa Doc: be cool with them Haitians"
    end
  end

  context '.field' do
    it 'adds field names' do
      Icss::Smurf::Base.field_names.should == [:smurfiness]
    end
    it 'adds field info' do
      Icss::Smurf::Base.fields.should == {:smurfiness => {:name => :smurfiness, :type => Integer} }
    end
    it 'inherits parent fields' do
      new_smurf_klass.field(:birthday, Date)
      Icss::Smurf::Poppa.field_names.should == [:smurfiness]
      Icss::Smurf::Poppa.fields.should == {:smurfiness => {:name => :smurfiness, :type => Integer} }
      new_smurf_klass.field_names.should == [:smurfiness, :birthday]
      new_smurf_klass.fields.should == {:smurfiness => {:name => :smurfiness, :type => Integer}, :birthday => {:name => :birthday, :type => Date} }
    end

    it 'sets accessor visibility' do
      new_smurf_klass.field(:field_1, Integer, :reader => :none)
      new_smurf_klass.field(:field_2, Integer, :writer => :protected, :accessor => :private)
      new_smurf = new_smurf_klass.new
      new_smurf.should     respond_to('field_1=')
      new_smurf.should_not respond_to('field_1')
      lambda{ new_smurf.field_2 = 3 }.should raise_error(NoMethodError, /protected method \`field_2=/)
      lambda{ new_smurf.field_2     }.should raise_error(NoMethodError, /private method \`field_2/)
    end

    it 'adds few methods' do
      (Icss::Smurf::Smurfette.methods - Class.methods).sort.should == [
        :add_after_receivers, :add_field_accessor, :add_field_info, :add_receiver,
        :after_receive, :after_receivers,
        :call_ancestor_chain, :consume_tuple,
        :doc, :doc=, :field, :field_names, :fields,
        :fullname, :namespace,
        :rcvr_remaining, :tuple_keys, :typename
      ]
    end
    it 'adds few methods' do
      (Icss::Smurf::Smurfette.new.methods - Object.methods).sort.should == [
        :_receive_attr, :attr_set?,
        :blondness, :blondness=, :doing_it, :doing_it=,
        :receive!, :receive_blondness, :receive_doing_it, :receive_smurfiness,
        :run_after_receivers,
        :smurfiness, :smurfiness=,
        :to_tuple, :unset!
      ]
    end
  end

  context '.fields' do
    #
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
      uncle_smurf.fields.should   == {:smurfiness => {:name => :smurfiness, :type => Integer} }
      baby_smurf.fields.should    == {:smurfiness => {:name => :smurfiness, :type => Integer} }
      #
      uncle_smurf.field(:smurfiness, Float, :by_the_way => 'pull my finger')
      Icss::Smurf::Poppa.fields.should   == {:smurfiness => {:name => :smurfiness, :type => Integer} }
      uncle_smurf.fields.should   == {:smurfiness => {:name => :smurfiness, :type => Float, :by_the_way => 'pull my finger'} }
      baby_smurf.fields.should    == {:smurfiness => {:name => :smurfiness, :type => Float, :by_the_way => 'pull my finger'} }
    end

    it 'does not override an existing method' do
      new_smurf_klass.class_eval{ def foo() "hello!" end }
      new_smurf_klass.field :foo, String
      new_smurf_klass.new.foo.should == "hello!"
    end
  end

  context 'instances' do
    it 'have accessors for each field' do
      [:smurfiness, :doing_it, :blondness].each do |f|
        smurfette.should respond_to(f)
        smurfette.should respond_to("#{f}=")
      end
      smurfette.blondness.should == nil
      smurfette.blondness = true
      smurfette.blondness.should == true
    end
  end

end
