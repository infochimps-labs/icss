require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'yaml'
require 'gorillib/object/try_dup'
require 'icss/receiver_model/acts_as_hash'
require 'icss/type'                   #
require 'icss/type/simple_types'      # Boolean, Integer, ...
require 'icss/type/named_type'        # class methods for a named type: .metamodel .doc, .fullname, &c
require 'icss/type/record_type'       # class methods for a record model: .field, .receive,
require 'icss/type/record_model'      # instance methods for a record model
require 'icss/type/type_factory'      # factory for instances based on type
require 'icss/type/structured_schema' # generate type from array, hash, &c schema
require 'icss/receiver_model'
require 'icss/type/record_schema'
require 'icss/type/record_field'
require ENV.root_path('spec/support/icss_test_helper')
include IcssTestHelper

module Icss
  module This
    module That
      class TheOther
        def bob
          'hi bob'
        end
      end
    end
    module Right
      class Here
        include Icss::Meta::RecordModel
      end
      class OverThere < Here
      end
    end
  end
  class ::Icss::Numeric < ::Numeric ; end
end

include IcssTestHelper

describe Icss::Meta::RecordSchema do

  BASIC_RECORD_SCHEMA = {:type => :record, :name => 'business.restaurant',
    :doc => "y'know, for food and stuff",
    :fields => [ { :name => 'menu', :type => 'string' } ] }
  before(:each) do
    remove_icss_constants('Business::Restaurant')
    remove_icss_constants(:LabExperiment, :DayOfWeek, :GeoCoordinates)
  end

  describe "With basic schema" do
    before(:each) do
      @model_klass = Icss::Meta::RecordSchema.receive(BASIC_RECORD_SCHEMA)
      @schema_writer = @model_klass._schema
    end

    it 'has schema_writer' do
      @schema_writer.type.should  == :record
      @schema_writer.fullname.should == :'business.restaurant'
      @schema_writer.fields.length.should == 1
    end

    it 'creates a named class' do
      @model_klass.name.to_s.should == 'Icss::Business::Restaurant'
      Icss::Business::Restaurant.fullname.should == :"business.restaurant"
      Icss::Business::Restaurant.doc.should == "y'know, for food and stuff"
    end

    it 'has accessors and receivers for the fields' do
      blank_model = Class.new{ include Icss::Meta::RecordModel }
      (@model_klass.public_methods - blank_model.public_methods).sort.should == [
        :_domain_id_field, :_schema, :is_a
      ].sort.uniq
      (@model_klass.public_instance_methods - Object.public_instance_methods).sort.should == [
        :attr_set?, :menu, :menu=, :receive!, :receive_menu
      ].sort.uniq
    end
  end

  describe '#is_a' do
    [
      [ [Icss::This::That::TheOther],               ['Icss::This::That::TheOther']],
      [ ['this.that.the_other'],                    ['Icss::This::That::TheOther'] ],
      [ ['this.right.here'],                        ['Icss::This::Right::Here',    'Icss::Meta::This::Right::HereModel'] ],
      [ ['this.that.the_other', 'this.right.here'], ['Icss::This::That::TheOther', 'Icss::Meta::This::Right::HereModel'] ],
    ].each do |given_is_a, expected_superklasses|
      it "sets a superclass from #{given_is_a}" do
        schema_hsh = BASIC_RECORD_SCHEMA.merge(:is_a => given_is_a)
        @model_klass = Icss::Meta::RecordSchema.receive(schema_hsh)
        expected_superklasses.each do |superklass|
          @model_klass.should < superklass.constantize
        end
      end
    end

    it 'does NOT follow superclasses of multiple inheritance parents' do
      schema_hsh = BASIC_RECORD_SCHEMA.merge(:is_a => ['this.that.the_other', 'this.right.over_there'])
      @model_klass = Icss::Meta::RecordSchema.receive(schema_hsh)
      @model_klass.should     <  Icss::This::That::TheOther
      @model_klass.should_not <  Icss::This::Right::OverThere
      @model_klass.should     <  Icss::This::Right::OverThere.metamodel
      @model_klass.should_not <  Icss::This::Right::Here
      @model_klass.should_not <  Icss::This::Right::Here.metamodel
    end

    it 'does allow explicitly-listed superclasses of multiple inheritance parents' do
      schema_hsh = BASIC_RECORD_SCHEMA.merge(:is_a => ['this.that.the_other', 'this.right.over_there', 'this.right.here'])
      @model_klass = Icss::Meta::RecordSchema.receive(schema_hsh)
      @model_klass.should     <  Icss::This::That::TheOther
      @model_klass.should_not <  Icss::This::Right::OverThere
      @model_klass.should     <  Icss::This::Right::OverThere.metamodel
      @model_klass.should_not <  Icss::This::Right::Here
      @model_klass.should     <  Icss::This::Right::Here.metamodel
    end
  end
end

describe Icss::Meta::RecordModel do
  context 'record schema' do
    before do
      @klass = Icss::Meta::TypeFactory.receive({
          'type'   => 'record',
          'name'   => 'lab_experiment',
          'is_a'   => ['this.that.the_other', 'this.right.here'],
          'fields' => [
            { 'name' => 'temperature', 'type' => 'float' },
            { 'name' => 'day', 'type' => {
                'name' => 'day_of_week', :type => 'enum',
                'symbols' => [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday] }},
            { 'name' => 'geo', 'type' => {
                :type => 'record', 'name' => 'geo_coordinates',
                'fields' => [
                  { 'name' => 'latitude',  'type' => 'float' },
                  { 'name' => 'longitude', 'type' => 'float' },
                  { 'name' => 'spatial_extent', 'type' =>
                    { 'type' => 'array', 'items' => {
                        'type' => 'array', 'items' => 'float' }}},
              ]}},
          ] })
      @obj = @klass.receive({ :temperature => 97.4, :day => 'tuesday',
          :geo => {
            'longitude' => '-97.75', :latitude => "30.03",
            'spatial_extent' => [ ['-97.75', '30.03'], ['-97.70', '30.1'], ['-97.90', '30.1'] ]
          } })
    end
    it 'handles array of record of ...' do
      @klass.to_s.should == 'Icss::LabExperiment'
      @obj.should be_a(@klass)
      @obj.should be_a(Icss::This::That::TheOther)
      @obj.should be_a(Icss::This::Right::Here.metamodel)
    end
    it 'receives data' do
      @obj.temperature.should == 97.4
      @obj.day.should == :tuesday
      @obj.geo.latitude.should == 30.03
      @obj.geo.longitude.should == -97.75
      @obj.geo.should be_a(Icss::GeoCoordinates)
      @obj.geo.spatial_extent.should == [ [-97.75, 30.03], [-97.70, 30.1], [-97.90, 30.1] ]
    end
  end
end
