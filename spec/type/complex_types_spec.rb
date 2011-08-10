require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/receiver_model/active_model_shim'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/named_schema'
require 'icss/type/has_fields'
require 'icss/type/named_schema'
require 'icss/type/record_type'
require 'icss/type/type_factory'
require 'icss/type/complex_types'

require 'awesome_print'

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
          @arr_klass = Icss::Meta::ArraySchema::Writer.receive_schema(schema)
          @arr_schema_writer = @arr_klass._schema
        end
        it 'round-trips the schema' do
          @arr_klass.to_schema.should == schema
        end
        it 'is a descendent of Array and its metatype' do
          @arr_klass.should < Array
          @arr_klass.should be_a Icss::Meta::ArraySchema
        end
        it 'has items and an item_factory' do
          @arr_klass.should respond_to(:items)
          @arr_klass.items.should == schema[:items]
          @arr_klass.item_factory.should == expected_item_factory
        end
        it 'has schema_writer' do
          @arr_schema_writer.type.should  == :array
          @arr_schema_writer.items.should == schema[:items]
          @arr_schema_writer.should be_valid
          @arr_schema_writer.type = :YO_ADRIAN
          @arr_schema_writer.should_not be_valid
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
          @arr_klass = Icss::Meta::HashSchema::Writer.receive_schema(schema)
          @arr_schema_writer = @arr_klass._schema
        end
        it 'round-trips the schema' do
          @arr_klass.to_schema.should == schema
        end
        it 'is a descendent of Hash and of its metatype' do
          @arr_klass.should < Hash
          @arr_klass.should be_a Icss::Meta::HashSchema
        end
        it 'has values and an value_factory' do
          @arr_klass.should respond_to(:values)
          @arr_klass.values.should == schema[:values]
          @arr_klass.value_factory.should == expected_value_factory
        end
        it 'has schema_writer' do
          @arr_schema_writer.type.should  == :map
          @arr_schema_writer.values.should == schema[:values]
          @arr_schema_writer.should be_valid
          @arr_schema_writer.type = :YO_ADRIAN
          @arr_schema_writer.should_not be_valid
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
          @arr_klass = Icss::Meta::EnumSchema::Writer.receive_schema(schema)
          @arr_schema_writer = @arr_klass._schema
        end
        it 'round-trips the schema' do
          expected_schema = schema.dup
          expected_schema[:symbols] = expected_schema[:symbols].map(&:to_sym)
          @arr_klass.to_schema.should == expected_schema
        end
        it 'is a descendent of Enum and of its metatype' do
          @arr_klass.should < Symbol
          @arr_klass.should be_a Icss::Meta::EnumSchema
        end
        it 'has symbols' do
          @arr_klass.should respond_to(:symbols)
          @arr_schema_writer.symbols.should == schema[:symbols].map(&:to_sym)
        end
        it 'has schema_writer' do
          @arr_schema_writer.type.should  == :enum
          @arr_schema_writer.should be_valid
          @arr_schema_writer.type = :YO_ADRIAN
          @arr_schema_writer.should_not be_valid
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

  # context Icss::Meta::UnionType do
  #   it 'receives simple unions' do
  #     uu = Icss::Meta::UnionType.receive([:int, :string])
  #     uu.declaration_flavors.should == [:primitive, :primitive]
  #     uu.to_schema.should == [:int, :string]
  #   end
  #
  #   it 'receives complex unions' do
  #     uu = Icss::Meta::UnionType.receive([ 'boolean', 'double',
  #         {'type' => 'array', 'items' => 'bytes'}])
  #     uu.declaration_flavors.should == [:primitive, :primitive]
  #     uu.to_schema.should == [:int, :string]
  #   end
  # end
end


    # it 'each core class .receive method' do
    #   Symbol.receive('hi').should == :hi
    #   Integer.receive(3.4).should == 3
    #   Float.receive("4.5").should == 4.5
    #   String.receive(4.5).should == "4.5"
    #   Time.receive('1985-11-05T04:03:02Z').should == Time.parse('1985-11-05T04:03:02Z')
    #   Date.receive('1985-11-05T04:03:02Z').should == Date.parse('1985-11-05')
    #   Boolean.receive("false").should == false
    #   NilClass.receive(nil).should == nil
    # end

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
