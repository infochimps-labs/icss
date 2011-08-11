require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/entity'
require 'icss/receiver_model/active_model_shim'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/named_schema'
require 'icss/type/has_fields'
require 'icss/type/named_schema'
require 'icss/type/record_type'
require 'icss/type/type_factory'
require 'icss/type/complex_types'
require 'icss/type/record_field'

module Icss
  module This
    module That
      class TheOther
      end
    end
  end
  Blinken = 7
end

require 'yaml'

def example_files(filename)
  Dir[ENV.root_path('examples/infochimps-catalog', filename+".icss.yaml")]
end

module Icss
  class Thing           < Icss::Entity ; end
  class Intangible      < Icss::Entity ; end

  class StructuredValue < Icss::Intangible ;  end
  class Rating          < Icss::StructuredValue  ; end


  class AggregateQuantity < Icss::StructuredValue ;  end
  class AggregateRating < Icss::Rating ;  end

  class ContactPoint    < Icss::StructuredValue  ; end


  class CreativeWork            < Thing ; end
  class Event           < Thing ; end
  class GeoCoordinates          < Thing ; end
  class MediaObject             < Thing ; end
  class Organization            < Thing ; end
  class Person          < Thing ; end
  class Place           < Thing ; end
  class PostalAddress   < ContactPoint ; end
  class Product                 < Thing ; end
  class Review          < Thing ; end
  class Photograph          < Thing ; end


end

icss_filenames = %w[
    schema_org/thing schema_org/place
  ].map{|fn| example_files(fn) }.flatten

icss_filenames[0..2].each do |icss_filename|
  hsh = YAML.load(File.open(icss_filename))
  p hsh.keys

  hsh['types'].each do |schema|
    ap schema
    type_klass = Icss::Meta::TypeFactory.receive(schema)
    ap type_klass
  end
end

describe Icss::Meta::TypeFactory do

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
  #
  # TEST_SCHEMA_FLAVORS = {
  #   :primitive => {
  #     'int'                      => Integer,
  #     'string'                   => String,
  #     :string                    => String,
  #   },
  #   :simple => {
  #     :date                      => Date,
  #     'time'                     => Time,
  #   },
  #   :is_type => {
  #     Icss::This::That::TheOther => Icss::This::That::TheOther,
  #   },
  #   :defined_type => {
  #     'this.that.the_other'      => ['this.that.the_other', 'Icss::This::That::TheOther'],
  #   },
  #   :complex_type => {
  #     # Complex Container Types: map, array, enum, fixed
  #     { 'type' => 'array',  'items' => 'string'  }                         => [Icss::Meta::ArraySchema::Writer, 'Icss::ArrayOfString'],
  #     { 'type' => 'map',    'values' => 'string' }                         => [Icss::Meta::HashSchema::Writer, 'Icss::HashOfString'],
  #
  #     { 'type' => 'map',    'values' =>
  #       {'type' => 'array', 'items' => 'int' } }                           => [Icss::Meta::HashSchema::Writer, false],
  #
  #     { 'type' => 'enum',   'name'  => 'Kind', 'symbols' => ['A','B','C']} => [Icss::Meta::EnumSchema::Writer, 'Icss::Kind'],
  #     { 'type' => 'fixed',  'name' => 'MD5',  'size' => 16}                => [Icss::Meta::FixedSchema::Writer, 'Icss::Md5'],
  #     { 'type' => 'record', 'name'  => 'bob'      }                        => [Icss::Meta::RecordType::Schema::Writer, 'Icss::Bob'],
  #     # { 'type' => 'record','name' => 'Node', 'fields' => [
  #     #     { 'name' => 'label',    'type' => 'string'},
  #     #     { 'name' => 'children', 'type' => {'type' => 'array', 'items' => 'Node'}}]} => Icss::Meta::RecordType,
  #     # { 'type' => 'map', 'values' => { 'name' => 'Foo', 'type' => 'record', 'fields' => [{'name' => 'label', 'type' => 'string'}]} } => Icss::HashType,
  #   },
  #   :union_type => {
  #     # [ 'boolean', 'double', {'type' => 'array', 'items' => 'bytes'}] => nil,
  #     # [ 'int', 'string' ]            => nil,
  #   },
  # }
  #
  # # context 'test schema:' do
  # #   TEST_SCHEMA_FLAVORS.each do |expected_schema_flavor, test_schemata|
  # #     test_schemata.each do |schema_dec, (expected_schema_klass, expected_type_klass)|
  # #       expected_type_klass ||= expected_schema_klass
  # #
  # #       it "classifies schema as #{expected_schema_flavor} for #{schema_dec.inspect[0..60]}" do
  # #         schema_flavor, schema_klass = Icss::Meta::TypeFactory.classify_schema_declaration(schema_dec)
  # #         schema_flavor.should        == expected_schema_flavor
  # #         schema_klass.to_s.should    == expected_schema_klass.to_s
  # #       end
  # #
  # #       it "creates type as expected_schema_klass for #{schema_dec.inspect[0..60]}" do
  # #         klass = Icss::Meta::TypeFactory.receive(schema_dec)
  # #         klass.to_s.should == expected_type_klass.to_s  unless (not expected_type_klass)
  # #       end
  # #     end
  # #   end
  # # end
  #
  # context 'nested schema' do
  #
  #   # it 'handles map of array of ...' do
  #   #   klass = Icss::Meta::TypeFactory.receive({
  #   #       'type' => 'map',    'values' => { 'type' => 'array', 'items' => 'int' } })
  #   #   # #<HashSchema::Writer @type=:map, @value_factory=Icss::ArrayOfInt, @name=nil>
  #   #   ap klass
  #   #   ap klass._schema
  #   #   klass.type.should == :map
  #   #   klass.value_factory.to_s.should == 'Icss::ArrayOfInt'
  #   #   klass.value_factory.type.should == :array
  #   #   klass.value_factory.item_factory.should == Integer
  #   #
  #   #   obj = klass.receive({ :tuesday => [ "1", 2, 3.4, nil ], :wednesday => nil, :thursday => [], 'friday' => [1.0] })
  #   #   obj.should == { :tuesday => [ 1, 2, 3, nil ], :wednesday => nil, :thursday => [], 'friday' => [1] }
  #   # end
  #
  #   # it 'handles array of record of ...' do
  #   #   klass = Icss::Meta::TypeFactory.receive({
  #   #       'type' => 'array',    'items' => {
  #   #         'type'   => 'record',
  #   #         'name'   => 'lab_experiment',
  #   #         'fields' => [
  #   #           { 'name' => 'day_of_week', 'type' => 'enum', 'symbols' => [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday] },
  #   #           { 'name' => 'temperature', 'type' => 'float' },
  #   #         ] } })
  #   #   # #<HashSchema::Writer @type=:map, @value_factory=Icss::ArrayOfInt, @name=nil>
  #   #   ap klass
  #   #   ap klass._schema
  #   #   ap klass.item_factory._schema
  #   #   klass.type.should == :array
  #   #   klass.item_factory.to_s.should == 'Icss::LabExperiment'
  #   #
  #   #   obj = klass.receive({ :tuesday => [ "1", 2, 3.4, nil ], :wednesday => nil, :thursday => [], 'friday' => [1.0] })
  #   #   obj.should == { :tuesday => [ 1, 2, 3, nil ], :wednesday => nil, :thursday => [], 'friday' => [1] }
  #   # end
  # end
end
