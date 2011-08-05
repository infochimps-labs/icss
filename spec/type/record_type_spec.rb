require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/named_type'
require 'icss/type/field_decorators'
require 'icss/type/receiver_decorators'
require 'icss/type/record_type'
require 'icss/type/record_field'

# module Icss::Smurf
#   class Base
#     include Icss::Type::RecordType
#     field :smurfiness, Integer
#   end
#   class Poppa < Base
#   end
#   module Brainy
#     include Icss::Type::RecordType
#     field :doing_it, Boolean
#   end
#   class Smurfette < Poppa
#     include Brainy
#     include Icss::Type::RecordType
#     field :blondness, Integer
#   end
# end
#
#
# describe Icss::Type::RecordField do
#   context 'asdf.receive' do
#     it 'is' do
#       (Icss::Type::RecordField.public_methods - Class.public_methods).sort.should == [
#         :add_receiver, :after_receive, :after_receivers, :consume_tuple,
#         :doc, :doc=, :field, :field_names, :fields,
#         :fullname, :namespace,
#         :rcvr_remaining, :receive, :schema_hash, :tuple_keys, :typename
#       ]
#     end
#     it 'works' do
#       hsh = { :name => :height, :type => Integer, :doc => 'How High',
#         :default  => 3, :required => false, :order => 'ascending', }
#       foo = Icss::Type::RecordField.receive(hsh)
#       foo.required.should be_false
#       foo.default.should == 3
#       foo.to_hash.should == hsh
#       foo.receive_order('descending')
#       foo.order.should == 'descending'
#     end
#   end
# end
#
# describe Icss::Type::RecordType do
#   let(:new_smurf_klass){ k = Class.new(Icss::Smurf::Poppa)  }
#   let(:poppa          ){ Icss::Smurf::Poppa.new() }
#   let(:smurfette      ){ Icss::Smurf::Smurfette.new() }
#   let(:module_smurf   ){ m = Module.new; m.send(:include, Icss::Type::RecordType) ; m }
#
#   context 'makes class a NamedType' do
#     it "with fullname, namespace, typename, and doc" do
#       [:fullname, :namespace, :typename, :doc].each do |meth|
#         Icss::Smurf::Smurfette.should         respond_to(meth)
#         Icss::Smurf::Smurfette.new.should_not respond_to(meth)
#       end
#     end
#     it "named after its class and containing module" do
#       Icss::Smurf::Smurfette.typename.should  == 'smurfette'
#       Icss::Smurf::Smurfette.namespace.should == 'smurf'
#       Icss::Smurf::Smurfette.fullname.should  == 'smurf.smurfette'
#     end
#     it "Lets us set the doc field" do
#       Icss::Smurf::Poppa.doc = "Poppa Doc: be cool with them Haitians"
#       Icss::Smurf::Poppa.doc.should     == "Poppa Doc: be cool with them Haitians"
#       Icss::Smurf::Smurfette.doc.should == "Poppa Doc: be cool with them Haitians"
#       Icss::Smurf::Smurfette.doc        =  "Gentlesmurfs prefer blondes"
#       Icss::Smurf::Smurfette.doc.should == "Gentlesmurfs prefer blondes"
#       Icss::Smurf::Poppa.doc.should     == "Poppa Doc: be cool with them Haitians"
#     end
#   end
#
#   context '.field' do
#     it 'adds field names' do
#       Icss::Smurf::Base.field_names.should == [:smurfiness]
#     end
#     it 'adds field info' do
#       Icss::Smurf::Base.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
#     end
#     it 'inherits parent fields' do
#       new_smurf_klass.field(:birthday, Date)
#       Icss::Smurf::Poppa.field_names.should == [:smurfiness]
#       Icss::Smurf::Poppa.fields.keys.should == [:smurfiness]
#       Icss::Smurf::Poppa.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
#       new_smurf_klass.field_names.should == [:smurfiness, :birthday]
#       new_smurf_klass.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
#       new_smurf_klass.fields[:birthday  ].to_hash.should == {:name => :birthday,   :type => Date}
#     end
#
#     it 'sets accessor visibility' do
#       new_smurf_klass.field(:field_1, Integer, :reader => :none)
#       new_smurf_klass.field(:field_2, Integer, :writer => :protected, :accessor => :private)
#       new_smurf = new_smurf_klass.new
#       new_smurf.should     respond_to('field_1=')
#       new_smurf.should_not respond_to('field_1')
#       lambda{ new_smurf.field_2 = 3 }.should raise_error(NoMethodError, /protected method \`field_2=/)
#       lambda{ new_smurf.field_2     }.should raise_error(NoMethodError, /private method \`field_2/)
#     end
#
#     it 'adds few methods' do
#       (Icss::Smurf::Smurfette.public_methods - Class.public_methods).sort.should == [
#         # :add_receiver, :after_receive, :after_receivers, :consume_tuple,
#         :doc, :doc=, :field, :field_names, :fields,
#         :fullname, :namespace,
#         # :rcvr_remaining, :receive, :tuple_keys,
#         :schema_hash, :typename
#       ]
#     end
#     it 'adds few methods' do
#       (Icss::Smurf::Smurfette.new.public_methods - Object.public_methods).sort.should == [
#         # :attr_set?,
#         :blondness, :blondness=, :doing_it, :doing_it=,
#         # :receive!, :receive_blondness, :receive_doing_it, :receive_smurfiness,
#         :smurfiness, :smurfiness=,
#         # :to_tuple
#       ]
#     end
#   end
#
#   context '.fields' do
#     #
#     it 'inheritance works without weirdness' do
#       Icss::Smurf::Poppa.field_names.should     == [:smurfiness]
#       Icss::Smurf::Smurfette.field_names.should == [:smurfiness, :doing_it, :blondness]
#       Icss::Smurf::Brainy.field_names.should    == [:doing_it]
#     end
#     #
#     it 'fields dynamically added to superclasses appear, in order of ancestry' do
#       new_smurf_klass.send(:include, module_smurf)
#       module_smurf.field_names.should == []
#       new_smurf_klass.field_names.should    == [:smurfiness]
#       #
#       module_smurf.field(:smurfberries, Integer)
#       new_smurf_klass.field_names.should    == [:smurfiness, :smurfberries]
#       #
#       new_smurf_klass.field(:singing, Boolean)
#       module_smurf.field(:smurfberry_crunch, Integer)
#       new_smurf_klass.field_names.should    == [:smurfiness, :smurfberries, :smurfberry_crunch, :singing]
#     end
#     #
#     it 're-announcing a field modifies its info hash downstream, but not its order' do
#       uncle_smurf = Class.new(Icss::Smurf::Poppa)
#       baby_smurf  = Class.new(uncle_smurf)
#       baby_smurf.field_names.should == [:smurfiness]
#       uncle_smurf.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
#       baby_smurf.fields[:smurfiness ].to_hash.should == {:name => :smurfiness, :type => Integer}
#       #
#       uncle_smurf.field(:smurfiness, Float, :validates => :numericality)
#       Icss::Smurf::Poppa.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Integer}
#       uncle_smurf.fields[:smurfiness].to_hash.should == {:name => :smurfiness, :type => Float, :validates => :numericality}
#       baby_smurf.fields[:smurfiness ].to_hash.should == {:name => :smurfiness, :type => Float, :validates => :numericality}
#     end
#
#     it 'does not override an existing method' do
#       new_smurf_klass.class_eval{ def foo() "hello!" end }
#       new_smurf_klass.field :foo, String
#       new_smurf_klass.new.foo.should == "hello!"
#     end
#   end
#
#   context 'instances' do
#     it 'have accessors for each field' do
#       [:smurfiness, :doing_it, :blondness].each do |f|
#         smurfette.should respond_to(f)
#         smurfette.should respond_to("#{f}=")
#       end
#       smurfette.blondness.should == nil
#       smurfette.blondness = true
#       smurfette.blondness.should == true
#     end
#   end
#
# end
