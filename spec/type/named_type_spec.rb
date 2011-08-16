require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/simple_types'
require 'icss/type/record_schema'

require 'icss/receiver_model/active_model_shim'
require 'icss/type/record_type'
require 'icss/type/named_schema'



  # context '.ensure_module_scope' do
  #   it 'adds a new child when parents exist' do
  #     Icss::This::That.should_not be_const_defined(:AlsoThis)
  #     new_module = Icss::Meta::TypeFactory.get_module_scope(%w[Icss This That AlsoThis])
  #     new_module.name.should == 'Icss::This::That::AlsoThis'
  #     Icss::This::That::AlsoThis.class.should == Module
  #     Icss::This::That.send(:remove_const, :AlsoThis)
  #   end
  #   it 'adds parents as necessary' do
  #     Icss.should_not be_const_defined(:Winken)
  #     new_module = Icss::Meta::TypeFactory.get_module_scope(%w[Icss Winken Blinken Nod])
  #     new_module.name.should == 'Icss::Winken::Blinken::Nod'
  #     Icss::Winken::Blinken::Nod.class.should == Module
  #     Icss::Winken::Blinken.class.should      == Module
  #     Icss::Winken.class.should               == Module
  #     Icss.send(:remove_const, :Winken)
  #   end
  # end

# describe Icss::Meta do
#   before do
#     @test_protocol_hsh = YAML.load(File.open(File.expand_path(File.dirname(__FILE__) + '/../test_icss.yaml')))
#     @simple_record_hsh = @test_protocol_hsh['types'].first
#   end
#
#   it 'loads from a hash' do
#     Icss::Meta::BaseType.receive!(@simple_record_hsh)
#     p [Icss::Meta::BaseType, Icss::Meta::BaseType.fields]
#     Icss::Meta::BaseType.fields.length.should == 3
#     ref_field = Icss::Meta::BaseType.fields.first
#     ref_field.name.should == 'my_happy_string'
#     ref_field.doc.should  =~ /field 1/
#     ref_field.type.name.should == :string
#   end
#
#   it 'makes a meta type' do
#     k = Icss::Meta::TypeFactory.make('icss.simple_type')
#     meta_type = Icss::RecordType.receive(@simple_record_hsh)
#     p meta_type
#     k.class_eval{ include Receiver }
#     meta_type.decorate_with_receivers(k)
#     meta_type.decorate_with_conveniences(k)
#     meta_type.decorate_with_validators(k)
#     p [k.fields, k.receiver_attr_names]
#   end
#
#
#   # it "has the *class* attributes of an avro record type" do
#   #   [:name, :doc, :fields, :is_a, ]
#   # end
#   #
#   # it "is an Icss::Meta::NamedSchema, an Icss::Meta::Type, and an Icss::Base" do
#   #   Icss::Meta::RecordType.should < Icss::Meta::NamedSchema
#   #   Icss::Meta::RecordType.should < Icss::Meta::Type
#   #   Icss::Meta::RecordType.should < Icss::Base
#   # end
#
# end

# context 'is_a (inheritance)' do
#     it 'knows its direct Icss superclass'
#     it 'knows its Icss mixin classes'
#   end
#
#   context 'synthesizing' do
#     it 'has a Meta model to '
#   end
