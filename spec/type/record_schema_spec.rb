require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'yaml'
require 'icss/type'                   #
require 'icss/type/simple_types'      # Boolean, Integer, ...
require 'icss/type/named_type'        # class methods for a named type: .metamodel .doc, .fullname, &c
require 'icss/type/record_type'       # class methods for a record model: .field, .receive,
require 'icss/type/record_model'      # instance methods for a record model
require 'icss/type/type_factory'      # factory for instances based on type
require 'icss/type/structured_schema' # generate type from array, hash, &c schema
require 'icss/receiver_model'
require 'icss/type/record_schema'
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
  end
  class ::Icss::Numeric < ::Numeric ; end
end

include IcssTestHelper

describe Icss::Meta::RecordSchema do

  BASIC_RECORD_SCHEMA = {:type => :record, :name => 'business.restaurant',
    :doc => "y'know, for food and stuff",
    :fields => [ { :name => 'name', :type => 'string' } ] }
  before do
    remove_icss_constants(['Icss::Business', 'Icss::Meta::Business'], [:Restaurant, :RestaurantType])
  end

  describe "With basic schema" do
    before do
      @model_klass = Icss::Meta::RecordSchema.receive(BASIC_RECORD_SCHEMA)
      @schema_writer = @model_klass._schema
    end

    it 'hi' do
      p BASIC_RECORD_SCHEMA
      p Icss::Meta::RecordSchema.ancestors

      @model_klass = Icss::Meta::RecordSchema.receive(BASIC_RECORD_SCHEMA)
      @schema_writer = @model_klass._schema
    end

    it 'has schema_writer' do
      @schema_writer.type.should  == :record
      @schema_writer.fullname.should == 'business.restaurant'
      @schema_writer.fields.length.should == 1
    end

    it 'creates a named class' do
      @model_klass.name.to_s.should == 'Icss::Business::Restaurant'
      Icss::Business::Restaurant.fullname.should == "business.restaurant"
      Icss::Business::Restaurant.doc.should == "y'know, for food and stuff"
    end

    it 'has accessors and receivers for the fields' do
      (@model_klass.public_methods - Class.methods).sort.should == [
        :_domain_id_field, :_schema,
        :fullname,  :namespace, :basename, :doc, :doc=,
        :fields, :field, :field_names,
        :rcvr, :rcvr_remaining, :receive, :after_receive, :after_receivers,
        :to_schema, :is_a, :metamodel,
      ].sort.uniq
      (@model_klass.public_instance_methods - Object.public_instance_methods).sort.should == [
        :attr_set?, :name, :name=, :receive!, :receive_name
      ].sort.uniq
    end
  end

  describe '#is_a' do
    [
      [ [Icss::This::That::TheOther], ['Icss::This::That::TheOther']],
      [ ['this.that.the_other'], ['Icss::This::That::TheOther'] ],
      [ ['geo.place'], ['Icss::Meta::ThingModel'] ],
      [ ['this.that.the_other', 'geo.place'], ['Icss::This::That::TheOther', 'Icss::Meta::Geo::PlaceModel', 'Icss::Meta::ThingModel'] ],
    ].each do |given_is_a, expected_superklasses|
      it "sets a superclass from #{given_is_a}" do
        schema_hsh = BASIC_RECORD_SCHEMA.merge(:is_a => given_is_a)
        @model_klass = Icss::Meta::RecordSchema.receive(schema_hsh)
        p [@model_klass.ancestors, @model_klass._schema]
        expected_superklasses.each do |superklass|
          @model_klass.should < superklass.constantize
        end
      end
    end

  end
end

describe Icss::Meta::RecordModel do
  # context 'enum schema' do
  #   it 'handles array of record of ...' do
  #     @klass = Icss::Meta::TypeFactory.receive({
  #         'name' => 'day_of_week', 'type' => 'enum', 'symbols' => [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
  #         })
  #     @obj = @klass.receive('tuesday')
  #     @klass.to_s.should == 'Icss::DayOfWeek'
  #   end
  # end


  # context '.receive' do
  #   it '' do
  #     Icss::Meta::RecordSchema.receive({:type => :record, :name => 'sixteen_bytes_long', :size => 16})
  #     Icss::SixteenBytesLong.receive('123456789_123456').should == '123456789_123456'
  #   end
  #   it 'raises an error on too-long value' do
  #     Icss::Meta::RecordSchema.receive({:type => :record, :name => 'sixteen_bytes_long', :size => 16})
  #     lambda{ Icss::SixteenBytesLong.receive('123456789_1234567') }.should raise_error(ArgumentError, /Wrong size for a record-length type sixteen_bytes_long: got 17, not 16/)
  #   end
  #   it 'returns nil on nil/empty string value' do
  #     Icss::Meta::RecordSchema.receive({:type => :record, :name => 'sixteen_bytes_long', :size => 16})
  #     Icss::SixteenBytesLong.receive(nil).should be_nil
  #     Icss::SixteenBytesLong.receive('').should be_nil
  #     Icss::SixteenBytesLong.receive(:"").should be_nil
  #   end
  # end

  context 'record schema' do

    # before do
    #   @klass = Icss::Meta::TypeFactory.receive({
    #       'type'   => 'record',
    #       'name'   => 'lab_experiment',
    #       'is_a'   => ['this.that.the_other'],
    #       'fields' => [
    #         { 'name' => 'temperature', 'type' => 'float' },
    #         { 'name' => 'day_of_week', 'type' => 'enum', 'symbols' => [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday] },
    #       ] })
    #   @obj = @klass.receive({ :temperature => 97.4, :day_of_week => 'tuesday' })
    # end
    # it 'handles array of record of ...' do
    #   @klass.to_s.should == 'Icss::LabExperiment'
    # end
    #
    # it 'is not larded up with lots of extra methods' do
    #   (@klass.public_methods - Class.public_methods).sort.should == [
    #     :doc, :doc=, :fullname, :basename, :namespace, :to_schema,
    #     :field, :field_names, :fields, :metamodel,
    #     :rcvr, :rcvr_remaining, :receive, :after_receive, :after_receivers,
    #     :_schema, :receive_fields,
    #   ].sort
    #   (@obj.public_methods - Object.new.public_methods).sort.should == [
    #     :bob,
    #     :day_of_week, :day_of_week=, :receive_day_of_week,
    #     :receive_temperature, :temperature, :temperature=,
    #     :receive!,
    #   ].sort
    # end
    #
    # it 'inherits with is_a' do
    #   @klass.should < Icss::This::That::TheOther
    #   @obj.bob.should == 'hi bob'
    # end

    # it 'handles array of record of ...' do
    #   klass = Icss::Meta::TypeFactory.receive({
    #       'type'   => 'record',
    #       'name'   => 'lab_experiment',
    #       'fields' => [
    #         { 'name' => 'temperature', 'type' => 'float' },
    #         { 'name' => 'day_of_week', 'type' => 'enum', 'symbols' => [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday] },
    #       ] })
    #   p [klass.ancestors]
    #   p [klass.metamodel]
    #   p [klass.ancestors]
    #   p [klass.singleton_class.ancestors]
    #
    #   puts '!!!!!!!!!'
    #
    #   p [klass, klass.fullname, klass.fields, klass.field_names, klass.public_methods - Class.public_methods]
    #   p [klass.singleton_class.public_methods - Class.public_methods]
    #   p [klass.singleton_class.public_instance_methods - Class.public_instance_methods]
    #   p [klass.metamodel.public_methods - Module.public_methods]
    #   p [klass.metamodel.public_instance_methods - Module.public_methods]
    #
    #   puts '!!!!!!!!!'
    #
    #   ap obj
    #
    #   puts '!!!!!!!!!'
    #   obj.temperature.should == 97.4
    #   obj.day_of_week.should == :tuesday
    #
    #   p [obj.respond_to?(:type), klass.respond_to?(:type)]
    # end

  end

  # describe Icss::Meta::RecordField do
  #   context 'attributes' do
  #     it 'accepts name, type, doc, default, required and order' do
  #       hsh = { :name => :height, :type => 'int', :doc => 'How High',
  #         :default  => 3, :required => false, :order => 'ascending', }
  #       foo = Icss::Meta::RecordField.receive(hsh)
  #       foo.required.should be_false
  #       foo.default.should == 3
  #       foo.receive_order('descending')
  #       foo.order.should == 'descending'
  #     end
  #   end
  # end

end
