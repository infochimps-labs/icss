require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'time'
require 'date'
require 'icss/type'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'

PRIMITIVE_TYPES_TO_TEST = {
  ::NilClass => [NilClass,   nil],  ::Boolean => [TrueClass, true],
  ::Integer  => [Integer,      1],  ::Long    => [Integer,      1],
  ::Float    => [Float,      1.0],  ::Double  => [Float,      1.0],
  ::String   => [String, "hello"],  ::Binary  => [String, "hello"],
}

describe 'Icss::PRIMITIVE_TYPES' do
  it('tests all of them'){ PRIMITIVE_TYPES_TO_TEST.keys.map(&:to_s).sort.should == Icss::PRIMITIVE_TYPES.values.map(&:to_s).sort }
  PRIMITIVE_TYPES_TO_TEST.each do |type_klass, (parent_base_class, parent_instance)|
    context type_klass do
      it 'is named in Icss::PRIMITIVE_TYPES' do
        typename = Icss::PRIMITIVE_TYPES.key(type_klass)
        type_klass.to_schema == typename
      end
      it 'is named in Icss::SIMPLE_TYPES' do
        typename = Icss::SIMPLE_TYPES.key(type_klass)
        type_klass.to_schema == typename
      end
      it 'returns its avro name as its schema' do
        schema = type_klass.to_schema
        schema.should be_a(Symbol)
        Icss::PRIMITIVE_TYPES[schema].should == type_klass
      end
      it 'is primitive? and simple?, but not record? or union?' do
        Icss::Meta::Type.primitive?( type_klass).should be_true
        Icss::Meta::Type.simple?(    type_klass).should be_true
        Icss::Meta::Type.union?(     type_klass).should be_false
        Icss::Meta::Type.record?(    type_klass).should be_false
      end

      it 'descends from a base type' do
        type_klass.should be <= parent_base_class unless (type_klass == Boolean)
        type_klass.receive(parent_instance).should be_a(parent_base_class)
      end

      it 'has .receive' do
        obj = type_klass.receive(parent_instance)
        case
        when type_klass == Boolean then obj.should be_a(TrueClass)
        when type_klass == Long    then obj.should be_a(Integer)
        when type_klass == Double  then obj.should be_a(Float)
        else                            obj.should be_a(type_klass)
        end
      end
    end
  end

  describe '.receive' do
    def self.it_correctly_converts(type, orig, desired)
      it "for #{type} converts #{orig.inspect} to #{desired.inspect}" do
        type.receive(orig).should == desired
      end
    end

    describe 'type coercion' do
      [
        [Symbol,   'foo', :foo], [Symbol, :foo, :foo], [Symbol, nil, nil],     [Symbol, '', nil],
        [Integer, '5', 5],       [Integer, 5,   5],    [Integer, nil, nil],    [Integer, '', nil],
        [Integer, '5', 5],       [Integer, 5,   5],    [Integer, nil, nil],    [Integer, '', nil],
        [Long,    '5', 5],       [Long,    5,   5],    [Long,    nil, nil],    [Long,    '', nil],
        [Float,   '5.2', 5.2],   [Float,   5.2, 5.2],  [Float, nil, nil],      [Float, '', nil],
        [Double,  '5.2', 5.2],   [Double,  5.2, 5.2],  [Double,nil, nil],      [Double,'', nil],
        [String,  'foo', 'foo'], [String, :foo, 'foo'], [String, nil, ""],     [String, '', ""],
        [String,  5.2, "5.2"],   [String, [1], "[1]"],  [String, 1, "1"],
        [Binary,  'foo', 'foo'], [Binary, :foo, 'foo'], [Binary, nil, ""],     [Binary, '', ""],
        [Binary,  5.2, "5.2"],   [Binary, [1], "[1]"],  [Binary, 1, "1"],
        [Time,  '1985-11-05T04:03:02Z',             Time.parse('1985-11-05T04:03:02Z')],
        [Time,  '1985-11-05T04:03:02+06:00',        Time.parse('1985-11-04T22:03:02Z')],
        [Time,  Time.parse('1985-11-05T04:03:02Z'), Time.parse('1985-11-05T04:03:02Z')],
        [Date,  Time.parse('1985-11-05T04:03:02Z'), Date.parse('1985-11-05')],
        [Date,  '1985-11-05T04:03:02Z',             Date.parse('1985-11-05')],
        [Date,  '1985-11-05T04:03:02+06:00',        Date.parse('1985-11-05')],
        [Time, nil, nil],  [Time, '', nil], [Time, 'blah', nil],
        [Date, nil, nil],  [Date, '', nil], [Date, 'blah', nil],
        [Boolean, '0', true],   [Boolean, 0, true],  [Boolean, '',  false], [Boolean, [],     true], [Boolean, nil, nil],
        [Boolean, '1', true],   [Boolean, 1, true],  [Boolean, '5', true],  [Boolean, 'true', true],
        [NilClass, nil, nil],
      ].each do |type, orig, desired|
        it_correctly_converts type, orig, desired
      end

      describe 'NilClass' do
        it 'only accepts nil' do
          lambda{ NilClass.receive('hello') }.should raise_error(ArgumentError, /must be initialized with nil, but \[hello\] was given/)
        end
      end
    end
  end
end


describe '::Boolean' do
  let(:true_bool ){ ::Boolean.new(true)  }
  let(:false_bool){ ::Boolean.new(false) }
  it("has #class Boolean" ){ (true_bool.class).should == ::Boolean ; (false_bool.class).should == ::Boolean }
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
      :instance_of? => [::TrueClass, ::FalseClass, ::Object],
      :is_a?        => [::TrueClass, ::FalseClass, ::Object],
      :kind_of?     => [::TrueClass, ::FalseClass, ::Object],
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

