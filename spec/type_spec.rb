require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'icss/type'
require 'icss/type/simple_types'

PRIMITIVE_TYPES_TO_TEST = [
  ::Icss::NilClassType, ::Icss::BooleanType, ::Icss::IntegerType, ::Icss::LongType,
  ::Icss::FloatType,    ::Icss::DoubleType,  ::Icss::StringType,  ::Icss::BinaryType ]

PRIMITIVE_TYPE_PARENTS = {
  ::Icss::NilClassType => [NilClass,  nil],   ::Icss::BooleanType => [TrueClass, true],
  ::Icss::IntegerType  => [Integer,      1],  ::Icss::LongType    => [Integer,      1],
  ::Icss::FloatType    => [Float,      1.0],  ::Icss::DoubleType  => [Float,      1.0],
  ::Icss::StringType   => [String, "hello"],  ::Icss::BinaryType  => [String, "hello"],
}

describe Icss::Meta::Type do
  context '.fullname_for' do
    it 'converts from avro-style' do
      Icss::Meta::Type.fullname_for('a.b.c').should                           == 'a.b.c'
      Icss::Meta::Type.fullname_for('one_to.tha_three.to_tha_fo').should      == 'one_to.tha_three.to_tha_fo'
    end
    it 'converts from ruby-style' do
      Icss::Meta::Type.fullname_for('A::B::C').should                         == 'a.b.c'
      Icss::Meta::Type.fullname_for('OneTo::ThaThree::ToThaFo').should        == 'one_to.tha_three.to_tha_fo'
      Icss::Meta::Type.fullname_for('Icss::OneTo::ThaThree::ToThaFo').should  == 'one_to.tha_three.to_tha_fo'
    end
    it 'FIXME: Icss::IntegerType etc do not round-trip'
  end
  context '.klassname_for' do
    it 'converts from avro-style' do
      Icss::Meta::Type.klassname_for('a.b.c').should                          == '::Icss::A::B::C'
      Icss::Meta::Type.klassname_for('one_to.tha_three.to_tha_fo').should     == '::Icss::OneTo::ThaThree::ToThaFo'
    end
    it 'converts from ruby-style' do
      Icss::Meta::Type.klassname_for('A::B::C').should                        == '::Icss::A::B::C'
      Icss::Meta::Type.klassname_for('OneTo.ThaThree.ToThaFo').should         == '::Icss::OneTo::ThaThree::ToThaFo'
      Icss::Meta::Type.klassname_for('Icss::OneTo::ThaThree::ToThaFo').should == '::Icss::OneTo::ThaThree::ToThaFo'
    end
  end
end

describe Icss::Meta::PrimitiveType do
  Icss::PRIMITIVE_TYPES.each do |typename, klass|
    it "is a factory for #{typename}" do
      Icss::Meta::PrimitiveType.make(typename).should == klass
      Icss::Meta::PrimitiveType.make(typename.to_s).should == klass
      Icss::Meta::SimpleType.make(   typename).should == klass
    end
  end
  it "is not a factory for other metatypes" do
    [:record, :enum, :fixed, :array, :map, :hash, :union ].each do |typename|
      lambda{ Icss::Meta::PrimitiveType.make(typename) }.should raise_error(ArgumentError, /No such primitive type/)
    end
  end
end

describe 'Icss::PRIMITIVE_TYPES' do
  it('tests all of them'){ PRIMITIVE_TYPES_TO_TEST.map(&:to_s).sort.should == Icss::PRIMITIVE_TYPES.values.map(&:to_s).sort }
  PRIMITIVE_TYPES_TO_TEST.each do |type_klass|
    primitive_parent, primitive_instance = PRIMITIVE_TYPE_PARENTS[type_klass]
    context type_klass do
      it 'is a primitive type' do
        type_klass.should     be_a( Icss::Meta::Type::Schema )
        type_klass.should     be_a( Icss::Meta::PrimitiveType::Schema )
        type_klass.should     be_a( Icss::Meta::SimpleType::Schema )
        type_klass.should       <   Icss::Meta::Type
        type_klass.should       <   Icss::Meta::PrimitiveType
        type_klass.should       <   Icss::Meta::SimpleType
      end
      it 'is primitive? and simple?, but not record? or union?' do
        Icss::Meta::Type.primitive?( type_klass).should be_true
        Icss::Meta::Type.simple?(    type_klass).should be_true
        Icss::Meta::Type.union?(     type_klass).should be_false
        Icss::Meta::Type.record?(    type_klass).should be_false
      end
      it 'is named in Icss::PRIMITIVE_TYPES' do
        typename = Icss::PRIMITIVE_TYPES.key(type_klass)
        type_klass.typename == typename
      end
      it 'has an empty namespace, and the fullname, schema and typename all match' do
        typename = Icss::PRIMITIVE_TYPES.key(type_klass)
        type_klass.fullname  == typename
        type_klass.to_schema == typename
        type_klass.typename  == typename
      end
      it 'has only a few more methods' do
        (type_klass.methods.sort  - primitive_parent.methods - [:new]).should == [
          :doc, :fullname, :namespace, :to_schema, :typename
        ]
        (type_klass.new(primitive_instance).methods.sort - primitive_instance.methods).should == []
      end
    end
  end
end
