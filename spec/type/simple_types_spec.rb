require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'time'
require 'date'
require 'icss/type'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'

SIMPLE_TYPES_TO_TEST = {
  ::Symbol         => [Symbol,    :bob],  ::Date            => [Date, Date.today],
  ::Time           => [Time,  Time.now],
  ::Icss::FilePath => [String,  "/tmp"],  ::Icss::Regexp    => [String,  "hel*o"],
  ::Icss::Url      => [String,"bit.ly"],  ::Icss::EpochTime => [Integer, Time.now.to_i],
}

describe 'Icss::SIMPLE_TYPES (non-primitive)' do
  it('tests all of them'){ SIMPLE_TYPES_TO_TEST.keys.map(&:to_s).sort.should == (::Icss::SIMPLE_TYPES.values - Icss::PRIMITIVE_TYPES.values).map(&:to_s).sort }
  SIMPLE_TYPES_TO_TEST.each do |type_klass, (parent_base_class, parent_instance)|
    context type_klass do
      it 'is named in Icss::SIMPLE_TYPES' do
        typename = Icss::SIMPLE_TYPES.key(type_klass)
        type_klass.to_schema == typename
      end
      it 'returns its avro name as its schema' do
        schema = type_klass.to_schema
        schema.should be_a(Symbol)
        Icss::SIMPLE_TYPES[schema].should == type_klass
      end
      it 'is primitive? and simple?, but not record? or union?' do
        Icss::Meta::Type.primitive?( type_klass).should be_false
        Icss::Meta::Type.simple?(    type_klass).should be_true
        Icss::Meta::Type.union?(     type_klass).should be_false
        Icss::Meta::Type.record?(    type_klass).should be_false
      end

      it 'descends from a base type' do
        type_klass.should be <= parent_base_class
        type_klass.receive(parent_instance).should be_a(parent_base_class)
      end

      it 'has .receive' do
        obj = type_klass.receive(parent_instance)
        obj.should be_a(type_klass) unless (type_klass == Icss::EpochTime)
      end

    end
  end
end
