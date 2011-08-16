require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/simple_types'
require 'icss/type/schema'
require 'icss/type/record_schema'
require ENV.root_path('spec/support/icss_test_helper')
include IcssTestHelper

module Icss
  module This
    module That
      class TheOther
      end
    end
    Blinken = 7
  end
end

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
    context 'identity schema return the IdenticalFactory' do
      [Object, Icss::Meta::IdenticalFactory].each do |type_name|
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
    # :structured_schema => {
    #   # Complex Container Types: map, array, enum, fixed
    #   { 'type' => 'array',  'items' => 'string'  }                         => [Icss::Meta::ArraySchema::Writer, 'Icss::ArrayOfString'],
    #   { 'type' => 'map',    'values' => 'string' }                         => [Icss::Meta::HashSchema::Writer, 'Icss::HashOfString'],
    #
    #   { 'type' => 'map',    'values' =>
    #
    #     {'type' => 'array', 'items' => 'int' } }                           => [Icss::Meta::HashSchema::Writer, false],
    #
    #   { 'type' => 'enum',   'name'  => 'Kind', 'symbols' => ['A','B','C']} => [Icss::Meta::EnumSchema::Writer, 'Icss::Kind'],
    #   { 'type' => 'fixed',  'name' => 'MD5',  'size' => 16}                => [Icss::Meta::FixedSchema::Writer, 'Icss::Md5'],
    #   { 'type' => 'record', 'name'  => 'bob'      }                        => [Icss::Meta::RecordSchema::Writer, 'Icss::Bob'],
    #   # { 'type' => 'record','name' => 'Node', 'fields' => [
    #   #     { 'name' => 'label',    'type' => 'string'},
    #   #     { 'name' => 'children', 'type' => {'type' => 'array', 'items' => 'Node'}}]} => Icss::Meta::RecordType,
    #   # { 'type' => 'map', 'values' => { 'name' => 'Foo', 'type' => 'record', 'fields' => [{'name' => 'label', 'type' => 'string'}]} } => Icss::HashType,
    # },
    # :union_type => {
    #   # [ 'boolean', 'double', {'type' => 'array', 'items' => 'bytes'}] => nil,
    #   # [ 'int', 'string' ]            => nil,
    # },
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
      end
    end
  end

  context 'nested schema' do

    # it 'handles map of array of ...' do
    #   klass = Icss::Meta::TypeFactory.receive({
    #       'type' => 'map',    'values' => { 'type' => 'array', 'items' => 'int' } })
    #   # #<HashSchema::Writer @type=:map, @value_factory=Icss::ArrayOfInt, @name=nil>
    #   ap klass
    #   ap klass._schema
    #   klass.type.should == :map
    #   klass.value_factory.to_s.should == 'Icss::ArrayOfInt'
    #   klass.value_factory.type.should == :array
    #   klass.value_factory.item_factory.should == Integer
    #
    #   obj = klass.receive({ :tuesday => [ "1", 2, 3.4, nil ], :wednesday => nil, :thursday => [], 'friday' => [1.0] })
    #   obj.should == { :tuesday => [ 1, 2, 3, nil ], :wednesday => nil, :thursday => [], 'friday' => [1] }
    # end

    # it 'handles array of record of ...' do
    #   klass = Icss::Meta::TypeFactory.receive({
    #       'type' => 'array',    'items' => {
    #         'type'   => 'record',
    #         'name'   => 'lab_experiment',
    #         'fields' => [
    #           { 'name' => 'day_of_week', 'type' => 'enum', 'symbols' => [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday] },
    #           { 'name' => 'temperature', 'type' => 'float' },
    #         ] } })
    #   # #<HashSchema::Writer @type=:map, @value_factory=Icss::ArrayOfInt, @name=nil>
    #   ap klass
    #   ap klass._schema
    #   ap klass.item_factory._schema
    #   klass.type.should == :array
    #   klass.item_factory.to_s.should == 'Icss::LabExperiment'
    #
    #   obj = klass.receive({ :tuesday => [ "1", 2, 3.4, nil ], :wednesday => nil, :thursday => [], 'friday' => [1.0] })
    #   obj.should == { :tuesday => [ 1, 2, 3, nil ], :wednesday => nil, :thursday => [], 'friday' => [1] }
    # end
  end
end
