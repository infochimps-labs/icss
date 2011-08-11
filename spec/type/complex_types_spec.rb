require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/entity'
require 'icss/receiver_model/active_model_shim'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/has_fields'
require 'icss/type/record_type'
require 'icss/type/type_factory'
require 'icss/type/named_schema'
require 'icss/type/complex_types'

module Icss
  module This
    module That
      class TheOther
      end
    end
  end
  Blinken = 7
  class Entity
  end
  module Core
    class Thing < Entity
    end
  end
end

describe 'complex types' do
  before do
    [ Icss.constants, Icss::Meta.constants ].flatten.each do |const|
      next unless (const.to_s =~ /(Array|Hash)Of\w+/)
      scopes = const.to_s.split(/::/); cc = scopes.pop ; mod = scopes.join('::').constantize;
      mod.send(:remove_const, cc) if mod.const_defined?(cc)
    end
  end

  describe Icss::Meta::ArraySchema::Writer do
    [
      [{:type => :array, :items => :'this.that.the_other'}, Icss::This::That::TheOther, ],
      [{:type => :array, :items => :'int'     },            Integer, ],
      [{:type => :array, :items => :'core.thing'},          Icss::Core::Thing, ],
    ].each do |schema, expected_item_factory|
      describe "With #{schema}" do
        before do
          @klass = Icss::Meta::ArraySchema::Writer.receive_schema(schema)
          @schema_writer = @klass._schema
        end
        it 'is a descendent of Array and its metatype' do
          @klass.should < Array
          @klass.should be_a Icss::Meta::ArraySchema
        end
        it 'has items and an item_factory' do
          @klass.should respond_to(:items)
          @klass.items.should == schema[:items]
          @klass.item_factory.should == expected_item_factory
        end
        it 'has schema_writer' do
          @schema_writer.type.should  == :array
          @schema_writer.items.should == schema[:items]
          @schema_writer.should be_valid
          @schema_writer.items = nil
          @schema_writer.should_not be_valid
        end
      end
    end

    context '.receive' do
      it 'generates an instance of the type' do
        Icss::Meta::ArraySchema::Writer.receive_schema({:type => :array, :items => :'int' })
        inst = Icss::ArrayOfInt.receive([1, 2.0, nil, "4.5", "8", "fnord"])
        inst.should be_a(Array)
        inst.should be_a(Icss::ArrayOfInt)
      end
      it 'with nil or "" gives nil; with [] gives []' do
        Icss::Meta::ArraySchema::Writer.receive_schema({:type => :array, :items => :'int' })
        inst = Icss::ArrayOfInt.receive(nil)
        inst.should be_nil
        inst = Icss::ArrayOfInt.receive('')
        inst.should be_nil
        inst = Icss::ArrayOfInt.receive([])
        inst.should == []
        inst = Icss::ArrayOfInt.receive({})
        inst.should == []
        inst.should be_a(Icss::ArrayOfInt)
      end
      it 'applies the item_factory' do
        Icss::Meta::ArraySchema::Writer.receive_schema({:type => :array, :items => :'int' })
        inst = Icss::ArrayOfInt.receive([1, 2.0, nil, "4.5", "8", "fnord"])
        inst.should eql([1, 2, nil, 4, 8, 0])  # (1 == 1.0) is true but 1.eql?(1.0) is false
      end
    end
  end

  describe Icss::Meta::HashSchema::Writer do
    [
      [{:type => :map, :values => :'this.that.the_other'}, Icss::This::That::TheOther, ],
      [{:type => :map, :values => :'int'     },            Integer,           ],
      [{:type => :map, :values => :'core.thing'},          Icss::Core::Thing, ],
    ].each do |schema, expected_value_factory|
      describe "With #{schema}" do
        before do
          @klass = Icss::Meta::HashSchema::Writer.receive_schema(schema)
          @schema_writer = @klass._schema
        end
        it 'is a descendent of Hash and of its metatype' do
          @klass.should < Hash
          @klass.should be_a Icss::Meta::HashSchema
        end
        it 'has values and an value_factory' do
          @klass.should respond_to(:values)
          @klass.values.should == schema[:values]
          @klass.value_factory.should == expected_value_factory
        end
        it 'has schema_writer' do
          @schema_writer.type.should  == :map
          @schema_writer.values.should == schema[:values]
          @schema_writer.should be_valid
          @schema_writer.values = nil
          @schema_writer.should_not be_valid
        end
      end
    end

    context '.receive' do
      it 'generates an instance of the type' do
        Icss::Meta::HashSchema::Writer.receive_schema({:type => :map, :values => :'int' })
        inst = Icss::HashOfInt.receive([1, 2.0, nil, "4.5", "8", "fnord"])
        inst.should be_a(Hash)
        inst.should be_a(Icss::HashOfInt)
      end
      it 'with nil or "" gives nil; with [] gives []' do
        Icss::Meta::HashSchema::Writer.receive_schema({:type => :map, :values => :'int' })
        inst = Icss::HashOfInt.receive(nil)
        inst.should be_nil
        inst = Icss::HashOfInt.receive('')
        inst.should be_nil
        inst = Icss::HashOfInt.receive([])
        inst.should == {}
        inst = Icss::HashOfInt.receive({})
        inst.should == {}
        inst.should be_a(Icss::HashOfInt)
      end
      it 'applies the value_factory' do
        Icss::Meta::HashSchema::Writer.receive_schema({:type => :map, :values => :'int' })
        inst = Icss::HashOfInt.receive({ :a => 1, 'b' => 2.0, :c => nil, 'd' => "4.5", :e => "8", 99 => "fnord"})
        inst.should eql({ :a => 1, 'b' => 2, :c => nil, 'd' => 4, :e => 8, 99 => 0})
      end
    end
  end


  describe Icss::Meta::EnumSchema::Writer do
    [
      {:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]},
      {:type => :enum, :name => 'always_awesome',      :symbols => %w[AWESOME]},
      {:type => :enum, :name => 'jackson.five',        :symbols => [:a, :b, :c]},
    ].each do |schema|
      describe "With #{schema}" do
        before do
          @klass = Icss::Meta::EnumSchema::Writer.receive_schema(schema)
          @schema_writer = @klass._schema
        end
        it 'is a descendent of Enum and of its metatype' do
          @klass.should < Symbol
          @klass.should be_a Icss::Meta::EnumSchema
        end
        it 'has symbols' do
          @klass.should respond_to(:symbols)
          @schema_writer.symbols.should == schema[:symbols].map(&:to_sym)
        end
        it 'has schema_writer' do
          @schema_writer.type.should  == :enum
          @schema_writer.should be_valid
          @schema_writer.symbols = []
          @schema_writer.should_not be_valid
        end
      end
    end

    context '.receive' do
      it 'applies the value_factory' do
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        inst = Icss::Games::CoinOutcomes.receive('heads')
        inst.should == :heads    ; inst.should be_a(Symbol)
        inst = Icss::Games::CoinOutcomes.receive(:heads)
        inst.should == :heads    ; inst.should be_a(Symbol)
        inst = Icss::Games::CoinOutcomes.receive('sideways')
        inst.should == :sideways ; inst.should be_a(Symbol)
      end
      it 'raises an error on non-included value' do
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        lambda{ Icss::Games::CoinOutcomes.receive('ace_of_spades') }.should raise_error(ArgumentError, /Cannot receive ace_of_spades: must be one of heads,tails,sideways/)
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :enum, :name => 'herb.caen', :symbols => %w[parseley sage rosemary thyme]})
        lambda{ Icss::Herb::Caen.receive('weed') }.should raise_error(ArgumentError, /Cannot receive weed: must be one of parseley,sage,rosemary,.../)
      end
      it 'raises an error on non-symbolizable value' do
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        lambda{ Icss::Games::CoinOutcomes.receive(77) }.should raise_error(NoMethodError, /undefined method .to_sym/)
      end
      it 'returns nil on nil/empty string value' do
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        Icss::Games::CoinOutcomes.receive(nil).should be_nil
        Icss::Games::CoinOutcomes.receive('').should be_nil
        Icss::Games::CoinOutcomes.receive(:"").should be_nil
      end
    end
  end

  describe Icss::Meta::FixedSchema::Writer do
    [
      {:type => :fixed, :name => 'geo_feature_category', :size => 1 },
      {:type => :fixed, :name => 'sixteen_bytes_long',   :size => 16 },
    ].each do |schema|
      describe "With #{schema}" do
        before do
          @klass = Icss::Meta::FixedSchema::Writer.receive_schema(schema)
          @schema_writer = @klass._schema
        end
        it 'has schema_writer' do
          @schema_writer.type.should  == :fixed
          @schema_writer.should be_valid
          @schema_writer.size = nil
          @schema_writer.should_not be_valid
        end

      end
    end

    context '.receive' do
      it 'applies the value_factory' do
        Icss::Meta::FixedSchema::Writer.receive_schema({:type => :fixed, :name => 'sixteen_bytes_long', :size => 16})
        Icss::SixteenBytesLong.receive('heads').should == 'heads'
        Icss::SixteenBytesLong.receive('123456789_123456').should == '123456789_123456'
      end
      it 'raises an error on too-long value' do
        Icss::Meta::FixedSchema::Writer.receive_schema({:type => :fixed, :name => 'sixteen_bytes_long', :size => 16})
        lambda{ Icss::SixteenBytesLong.receive('123456789_1234567') }.should raise_error(ArgumentError, /Length of fixed type sixteen_bytes_long out of bounds: 123456789_1234567 is too large/)
      end
      it ' on non-stringlike value' do
        Icss::Meta::FixedSchema::Writer.receive_schema({:type => :fixed, :name => 'sixteen_bytes_long', :size => 16})
        lambda{ Icss::SixteenBytesLong.receive(77) }.should raise_error(ArgumentError, /Value for this field must be Stringlike/)
      end
      it 'returns nil on nil/empty string value' do
        Icss::Meta::FixedSchema::Writer.receive_schema({:type => :fixed, :name => 'sixteen_bytes_long', :size => 16})
        Icss::SixteenBytesLong.receive(nil).should be_nil
        Icss::SixteenBytesLong.receive('').should be_nil
        Icss::SixteenBytesLong.receive(:"").should be_nil
      end
    end
  end
end

# describe 'type coercion' do
#   [
#
#     [Array,  ['this', 'that', 'thother'], ['this', 'that', 'thother'] ],
#     [Array,  ['this,that,thother'],       ['this,that,thother'] ],
#     [Array,   'this,that,thother',        ['this,that,thother'] ],
#     [Array,  'alone', ['alone'] ],
#     [Array,  '',      []        ],
#     [Array,  nil,     nil       ],
#     [Hash,   {:hi => 1}, {:hi => 1}], [Hash,   nil,     nil],    [Hash,   "",      {}], [Hash,   [],      {}], [Hash,   {},      {}],
#     [Object,  {:foo => [1]}, {:foo => [1]} ], [Object, nil, nil], [Object, 1, 1],
#   ].each do |type, orig, desired|
#     it_correctly_converts type, orig, desired
#   end

# describe 'controversially' do
#   [
#     [Hash,  ['does no type checking'],      ['does no type checking'] ],
#     [Hash,   'does no type checking',        'does no type checking'  ],
#   ].each do |type, orig, desired|
#     it_correctly_converts type, orig, desired
#   end
# end
