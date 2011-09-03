require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'gorillib/object/try_dup'
require 'icss/receiver_model/acts_as_hash'
require 'icss/type'                   #
require 'icss/type/simple_types'      # Boolean, Integer, ...
require 'icss/type/named_type'        # class methods for a named type: .metamodel .doc, .fullname, &c
require 'icss/type/record_type'       # class methods for a record model: .field, .receive,
require 'icss/type/record_model'      # instance methods for a record model
require 'icss/type/type_factory'      # turn schema into types
require 'icss/type/structured_schema' # loads array, hash, enum, fixed and simple schema
require 'icss/receiver_model/active_model_shim'
require 'icss/type/record_schema'     # loads array, hash, enum, fixed and simple schema
require 'icss/type/record_field'

require ENV.root_path('spec/support/icss_test_helper')
include IcssTestHelper

describe Icss::Meta::TypeFactory do

  describe '.receive' do
    context 'simple type' do
      SIMPLE_TYPES_TO_TEST.each do |type_name, (expected_klass, _pkl, _pinst)|
        it 'turns type_name into expected klass' do
          Icss::Meta::TypeFactory.receive(type_name.to_sym).should == expected_klass
          Icss::Meta::TypeFactory.receive(type_name.to_s  ).should == expected_klass
        end
        it 'turns klass into expected klass' do
          Icss::Meta::TypeFactory.receive(expected_klass     ).should == expected_klass
        end
      end
    end
    [Object, Icss::Meta::IdenticalFactory].each do |type_name|
      it "#{type_name} schema return the IdenticalFactory" do
        Icss::Meta::TypeFactory.receive(type_name).should == Icss::Meta::IdenticalFactory
      end
    end
  end
  TEST_SCHEMA_FLAVORS = {
    :is_type => {
      Icss::This::That::TheOther => Icss::This::That::TheOther,
    },
    :named_type => {
      'this.that.the_other' => ['this.that.the_other', Icss::This::That::TheOther],
      'this.blinken'        => ['this.blinken',        Icss::This::Blinken],
    },
    :structured_schema => {
      # Complex Container Types: map, array, enum, fixed
      { 'type' => :array,  'items'  => :string  }                             => [Icss::Meta::ArraySchema, 'Icss::ArrayOfString'],
      { 'type' => :map,    'values' => :string }                              => [Icss::Meta::HashSchema, 'Icss::HashOfString'],
      { 'type' => :map,    'values' => {'type' => :array, 'items' => :int } } => [Icss::Meta::HashSchema, 'Icss::HashOfArrayOfInteger'],
      { 'name'   => 'Kind', 'type' => :enum,   'symbols' => [:A, :B, :C]}      => [Icss::Meta::EnumSchema, 'Icss::Kind'],
      { 'name'   => 'MD5',  'type' => :fixed,  'size' => 16}                   => [Icss::Meta::FixedSchema, 'Icss::Md5'],
      { 'name'   => 'bob',  'type' => :record,    }                            => [Icss::Meta::RecordSchema, 'Icss::Bob'],
      { 'name'   => 'node', 'type' => :record, 'fields' => [
          { 'name' => :label,    'type' => :string},
          { 'name' => :children, 'type' => {'type' => :array, 'items' => :string}}]} => [Icss::Meta::RecordSchema, 'Icss::Node'],
      { 'type' => :map, 'values' => {
          'name' => 'Foo', 'type' => :record, 'fields' => [{'name' => :label, 'type' => :string}]} } => [Icss::Meta::HashSchema, 'Icss::HashOfFoo' ],
    },
    :union_type => {
      # [ 'boolean', 'double', {'type' => 'array', 'items' => 'bytes'}] => nil,
      # [ 'int', 'string' ]            => nil,
    },
  }
  context 'test schema:' do
    TEST_SCHEMA_FLAVORS.each do |expected_schema_flavor, test_schemata|
      test_schemata.each do |schema_dec, (expected_schema_klass, expected_type_klass)|
        expected_type_klass ||= expected_schema_klass

        it "classifies schema as #{expected_schema_flavor} for #{schema_dec.inspect[0..60]}" do
          schema_flavor, schema_klass = Icss::Meta::TypeFactory.classify_schema_declaration(schema_dec)
          schema_flavor.should        == expected_schema_flavor
          schema_klass.to_s.should    == expected_schema_klass.to_s
        end

        it "creates type as expected_schema_klass for #{schema_dec.inspect[0..60]}" do
          klass = Icss::Meta::TypeFactory.receive(schema_dec)
          klass.to_s.should == expected_type_klass.to_s  unless (not expected_type_klass)
        end

        unless expected_type_klass.to_s =~ /Icss::This/
          it "round-trips schema #{schema_dec.to_s[0..140]}" do
            klass = Icss::Meta::TypeFactory.receive(schema_dec)
            klass.to_schema.should == schema_dec
          end
        end
      end
    end
  end

end
