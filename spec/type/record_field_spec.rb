require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/receiver_model/active_model_shim'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/has_fields'
require 'icss/type/record_type'
require 'icss/type/named_schema'
require 'icss/type/type_factory'
require 'icss/type/complex_types'
require 'icss/type/record_field'


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
end

describe Icss::Meta::RecordField do
  context 'attributes' do
    it 'accepts name, type, doc, default, required and order' do
      hsh = { :name => :height, :type => 'int', :doc => 'How High',
        :default  => 3, :required => false, :order => 'ascending', }
      foo = Icss::Meta::RecordField.receive(hsh)
      foo.required.should be_false
      foo.default.should == 3
      foo.receive_order('descending')
      foo.order.should == 'descending'
    end
  end
end

describe Icss::Meta::RecordType do

  context 'record schema' do
    before do
      @klass = Icss::Meta::TypeFactory.receive({
          'type'   => 'record',
          'name'   => 'lab_experiment',
          'is_a'   => ['this.that.the_other'],
          'fields' => [
            { 'name' => 'temperature', 'type' => 'float' },
            { 'name' => 'day_of_week', 'type' => 'enum', 'symbols' => [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday] },
          ] })
      @obj = @klass.receive({ :temperature => 97.4, :day_of_week => 'tuesday' })
    end
    it 'handles array of record of ...' do
      @klass.to_s.should == 'Icss::LabExperiment'
    end

    it 'is not larded up with lots of extra methods' do
      (@klass.public_methods - Class.public_methods).sort.should == [
        :doc, :doc=, :fullname, :typename, :namespace, :to_schema,
        :field, :field_names, :fields, :metatype,
        :rcvr, :rcvr_remaining, :receive, :after_receive, :after_receivers,
        :_schema, :receive_fields,
      ].sort
      (@obj.public_methods - Object.new.public_methods).sort.should == [
        :bob,
        :day_of_week, :day_of_week=, :receive_day_of_week,
        :receive_temperature, :temperature, :temperature=,
        :receive!,
      ].sort
    end

    it 'inherits with is_a' do
      @klass.should < Icss::This::That::TheOther
      @obj.bob.should == 'hi bob'
    end

    # it 'handles array of record of ...' do
    #   klass = Icss::Meta::TypeFactory.receive({
    #       'type'   => 'record',
    #       'name'   => 'lab_experiment',
    #       'fields' => [
    #         { 'name' => 'temperature', 'type' => 'float' },
    #         { 'name' => 'day_of_week', 'type' => 'enum', 'symbols' => [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday] },
    #       ] })
    #   p [klass.ancestors]
    #   p [klass.metatype]
    #   p [klass.ancestors]
    #   p [klass.singleton_class.ancestors]
    #
    #   puts '!!!!!!!!!'
    #
    #   p [klass, klass.fullname, klass.fields, klass.field_names, klass.public_methods - Class.public_methods]
    #   p [klass.singleton_class.public_methods - Class.public_methods]
    #   p [klass.singleton_class.public_instance_methods - Class.public_instance_methods]
    #   p [klass.metatype.public_methods - Module.public_methods]
    #   p [klass.metatype.public_instance_methods - Module.public_methods]
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

end
