require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/simple_types'

SIMPLE_TYPES_TO_TEST = [
  ::Icss::SymbolType, ::Icss::DateType, ::Icss::TimeType, ::Icss::Text,
  ::Icss::FilePath, ::Icss::Regexp, ::Icss::Url, ::Icss::EpochTime,
]

describe 'Icss::SIMPLE_TYPES (non-primitive)' do
  it('tests all of them'){ SIMPLE_TYPES_TO_TEST.map(&:to_s).sort.should == (::Icss::SIMPLE_TYPES.values - Icss::PRIMITIVE_TYPES.values).map(&:to_s).sort }
  SIMPLE_TYPES_TO_TEST.each do |type_klass|
    context type_klass do
      it 'is a simple type' do
        type_klass.should     be_a( Icss::Meta::Type )
        type_klass.should     be_a( Icss::Meta::SimpleType )
        type_klass.new.should_not be_a( Icss::Meta::SimpleType )
      end
      it 'is primitive? and simple?, but not record? or union?' do
        type_klass.should_not be_primitive
        type_klass.should     be_simple
        type_klass.should_not be_union
        type_klass.should_not be_record
      end
      it 'is named in Icss::SIMPLE_TYPES' do
        typename = Icss::SIMPLE_TYPES.key(type_klass)
        type_klass.typename == typename
      end
      it 'has an empty namespace, and the fullname, schema and typename all match' do
        typename = Icss::SIMPLE_TYPES.key(type_klass)
        type_klass.fullname  == typename
        type_klass.to_schema == typename
        type_klass.typename  == typename
      end
    end
  end
end

describe Icss::Boolean do
  let(:true_bool ){ Icss::Boolean.new(true)  }
  let(:false_bool){ Icss::Boolean.new(false) }
  it("has #class Boolean" ){ (true_bool.class).should == Icss::Boolean ; (false_bool.class).should == Icss::Boolean }
  describe 'mimicking true/false' do
    it(":!"     ){ (! true_bool).should    == (! true)     ; (! false_bool).should    == (! false)     }
    it(":nil?"  ){ (true_bool.nil?).should == (true.nil?)  ; (false_bool.nil?).should == (false.nil?)  }
    it(":to_s"  ){ (true_bool.to_s).should == (true.to_s)  ; (false_bool.to_s).should == (false.to_s)  }
    { :!=           => [true, false, nil],
      :!~           => [true, false, nil],
      :&            => [true, false, nil],
      :<=>          => [true, false, nil],
      :==           => [true, false, nil],
      :===          => [true, false, nil],
      :=~           => [true, false, nil],
      :^            => [true, false, nil],
      :eql?         => [true, false, nil],
      :|            => [true, false, nil],
      :instance_of? => [TrueClass, FalseClass, Object],
      :is_a?        => [TrueClass, FalseClass, Object],
      :kind_of?     => [TrueClass, FalseClass, Object],
    }.each do |meth, meth_args|
      it meth do
        meth_args.each do |meth_arg|
          true_bool.send( meth, meth_arg).should equal(true.send( meth, meth_arg))
          false_bool.send(meth, meth_arg).should equal(false.send(meth, meth_arg))
        end
      end
    end
  end
end
