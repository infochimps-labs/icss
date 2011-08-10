require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/receiver_model/active_model_shim'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/named_schema'
require 'icss/type/has_fields'
require 'icss/type/named_schema'
require 'icss/type/record_type'
require 'icss/type/type_factory'
require 'icss/type/complex_types'

require 'awesome_print'


describe Icss::Meta::TypeFactory do

  module Icss
    module This
      module That
        class TheOther
        end
      end
    end
    Blinken = 7
  end

  # context '.receive' do
  #   it 'on a primitive type' do
  #     Icss::PRIMITIVE_TYPES.each do |al, kl|
  #       Icss::Meta::TypeFactory.receive(al).should == kl
  #     end
  #     Icss::Meta::TypeFactory.receive('string').should == String
  #     Icss::Meta::TypeFactory.receive('int'   ).should == Integer
  #   end
  #   it 'on a simple type' do
  #     Icss::SIMPLE_TYPES.each do |al, kl|
  #       Icss::Meta::TypeFactory.receive(al).should == kl
  #     end
  #   end
  #   # it 'on a named type' do
  #   #   Icss::Meta::TypeFactory.receive('this.that.the_other'     ).should == Icss::This::That::TheOther
  #   #   Icss::Meta::TypeFactory.receive(Icss::This::That::TheOther).should == Icss::This::That::TheOther
  #   # end
  #   # it 'on a union type (array)' do
  #   #   uu = Icss::Meta::TypeFactory.receive([ 'this.that.the_other', Integer ])
  #   #   uu.should be_a(Icss::UnionType)
  #   # end
  # end

  TEST_SCHEMA = {
    :primitive => {
      'int'                      => Integer,
      'string'                   => String,
      :string                    => String,
    },
    :simple => {
      :date                      => Date,
      'time'                     => Time,
    },
    :is_type => {
      Icss::This::That::TheOther => Icss::This::That::TheOther,
    },
    :defined_type => {
      'this.that.the_other'      => :'this.that.the_other',
    },
    :complex_type => {
      # Complex Container Types: map, array, enum, fixed
      { 'type' => 'map',     'values' => 'string' } => 'Icss::Meta::HashSchema::Writer',
      { 'type' => 'array',   'items' => 'string'  } => 'Icss::Meta::ArraySchema::Writer',
      { 'type' => 'enum',    'name'  => 'Kind', 'symbols' => ['A','B','C']} => Icss::Meta::EnumSchema::Writer,
      # { 'type' => 'fixed', 'name' => 'MD5',  'size' => 16} => Icss::Meta::FixedType,
      { 'type' => 'record', 'name'  => 'bob'      } => Icss::Meta::RecordType,
      # { 'type' => 'record','name' => 'Node', 'fields' => [
      # { 'name' => 'label',    'type' => 'string'}, { 'name' => 'children', 'type' => {'type' => 'array', 'items' => 'Node'}}]} => Icss::Meta::RecordType,
      # { 'type' => 'map', 'values' => { 'name' => 'Foo', 'type' => 'record', 'fields' => [{'name' => 'label', 'type' => 'string'}]} } => Icss::HashType,
    },
    :union_type => {
      # [ 'boolean', 'double', {'type' => 'array', 'items' => 'bytes'}] => nil,
      # [ 'int', 'string' ]            => nil,
    },
  }
  context '.classify_schema_declaration' do
    TEST_SCHEMA.each do |schema_dec, (expected_schema_flavor, expected_schema_klass)|
      it "returns #{expected_schema_flavor} for #{schema_dec.inspect[0..60]}" do
        # ap [schema_dec, expected_schema_flavor, expected_schema_klass]

        schema_flavor, schema_klass = Icss::Meta::TypeFactory.classify_schema_declaration(schema_dec)
        ap [__FILE__, 'WHAT WHAT', schema_flavor, schema_klass]
        schema_flavor.should        == expected_schema_flavor
        schema_klass.to_s.should    == expected_schema_klass.to_s
      end
    end
  end

  context '.receive' do
    TEST_SCHEMA.each do |schema_dec, (expected_schema_flavor, expected_schema_klass)|
      it "successfully for #{schema_dec.inspect[0..60]}" do
        klass = Icss::Meta::TypeFactory.receive(schema_dec)
        ap [__FILE__, 'YAY YAY', klass, schema_dec]
      end
    end
  end

end


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

