require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'gorillib/object/try_dup'
require 'icss/receiver_model/acts_as_hash'
require 'icss/type'                   #
require 'icss/type/simple_types'      # Boolean, Integer, ...
require 'icss/type/named_type'        # class methods for a named type: .metamodel .doc, .fullname, &c
require 'icss/type/record_type'       # class methods for a record model: .field, .receive,
require 'icss/type/record_model'      # instance methods for a record model
#
require 'icss/type/type_factory'      #
require 'icss/type/structured_schema'

module Icss
  module TestStrSch
    module Foo
      class Bar
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

  describe Icss::Meta::ArraySchema do
    [
      [{:type => :array, :items => :'test_str_sch.foo.bar'}, Icss::TestStrSch::Foo::Bar, ],
      [{:type => :array, :items => :'int'     },            Integer, ],
      [{:type => :array, :items => :'core.thing'},          Icss::Core::Thing, ],
    ].each do |schema, expected_item_factory|
      describe "With #{schema}" do
        before do
          @model_klass = Icss::Meta::ArraySchema.receive(schema)
          @schema_writer = @model_klass._schema
        end
        it 'is a descendent of Array and its metatype' do
          @model_klass.should < Array
          @model_klass.should be_a Icss::Meta::ArrayType
          @model_klass.should be_a Icss::Meta::NamedType
        end
        it 'has items and an item_factory' do
          @model_klass.should respond_to(:items)
          @model_klass.items.should == expected_item_factory
        end
        it 'has schema_writer' do
          @schema_writer.type.should  == :array
          @schema_writer.to_hash.should == schema
          # @schema_writer.should be_valid
          @schema_writer.items = nil
          # @schema_writer.should_not be_valid
        end
      end
    end

    context "klass name" do
      [
        [ 'ArrayOfSymbol', :symbol  ],
        [ 'ArrayOfArrayOfInteger', { :type => :array, :items => :int } ],
        [ 'ArrayOfHashOfArrayOfString', { :type => :map, :values => { :type => :array, :items => :string } } ],
        [ 'ArrayOfTestStrSchDotFooDotBar', 'test_str_sch.foo.bar' ],
        [ 'ArrayOfHashOfArrayOfTestStrSchDotFooDotBar', { :type => :map, :values => { :type => :array, :items => 'test_str_sch.foo.bar' } } ],
      ].each do |expected_name, items_schema|
        it "is #{expected_name} for #{items_schema}" do
          schema = {:type => :array, :items => items_schema }
          kl = Icss::Meta::ArraySchema.receive(schema)
          kl.fullname.should == expected_name
        end
      end
    end

  end

  describe Icss::Meta::ArrayType do

    context '.receive' do
      it 'generates an instance of the type' do
        Icss::Meta::ArraySchema.receive({:type => :array, :items => :'int' })
        inst = Icss::ArrayOfInteger.receive([1, 2.0, nil, "4.5", "8", "fnord"])
        inst.should be_a(Array)
        inst.should be_a(Icss::ArrayOfInteger)
      end
      it 'with nil or "" gives nil; with [] gives []' do
        Icss::Meta::ArraySchema.receive({:type => :array, :items => :'int' })
        inst = Icss::ArrayOfInteger.receive(nil)
        inst.should be_nil
        inst = Icss::ArrayOfInteger.receive('')
        inst.should be_nil
        inst = Icss::ArrayOfInteger.receive([])
        inst.should == []
        inst = Icss::ArrayOfInteger.receive({})
        inst.should == []
        inst.should be_a(Icss::ArrayOfInteger)
      end
      it 'applies the item_factory' do
        Icss::Meta::ArraySchema.receive({:type => :array, :items => :'int' })
        inst = Icss::ArrayOfInteger.receive([1, 2.0, nil, "4.5", "8", "fnord"])
        inst.should eql([1, 2, nil, 4, 8, 0])  # (1 == 1.0) is true but 1.eql?(1.0) is false
      end
    end
  end

  describe Icss::Meta::HashSchema do
    [
      [{:type => :map, :values => :'test_str_sch.foo.bar'}, Icss::TestStrSch::Foo::Bar, ],
      [{:type => :map, :values => :'int'     },            Integer,           ],
      [{:type => :map, :values => :'core.thing'},          Icss::Core::Thing, ],
    ].each do |schema, expected_value_factory|
      describe "With #{schema}" do
        before do
          @model_klass = Icss::Meta::HashSchema.receive(schema)
          @schema_writer = @model_klass._schema
        end
        it 'is a descendent of Hash and of its metatype' do
          @model_klass.should < Hash
          @model_klass.should be_a Icss::Meta::HashType
          @model_klass.should be_a Icss::Meta::NamedType
        end
        it 'has values and an value_factory' do
          @model_klass.should respond_to(:values)
          @model_klass.values.should == expected_value_factory
        end
        it 'has schema_writer' do
          @schema_writer.type.should   == :map
          @schema_writer.to_hash.should == schema
          # @schema_writer.should be_valid
          @schema_writer.values = nil
          # @schema_writer.should_not be_valid
        end
      end
    end

    context "klass name" do
      [
        [ 'HashOfSymbol', :symbol  ],
        [ 'HashOfHashOfInteger', { :type => :map, :values => :int } ],
        [ 'HashOfHashOfArrayOfString', { :type => :map, :values => { :type => :array, :items => :string } } ],
        [ 'HashOfTestStrSchDotFooDotBar', 'test_str_sch.foo.bar' ],
        [ 'HashOfHashOfArrayOfTestStrSchDotFooDotBar', { :type => :map, :values => { :type => :array, :items => 'test_str_sch.foo.bar' } } ],
      ].each do |expected_name, values_schema|
        it "is #{expected_name} for #{values_schema}" do
          schema = {:type => :map, :values => values_schema }
          kl = Icss::Meta::HashSchema.receive(schema)
          kl.fullname.should == expected_name
        end
      end
    end

  end

  describe Icss::Meta::HashType do
    context '.receive' do
      it 'generates an instance of the type' do
        Icss::Meta::HashSchema.receive({:type => :map, :values => :'int' })
        inst = Icss::HashOfInteger.receive([1, 2.0, nil, "4.5", "8", "fnord"])
        inst.should be_a(Hash)
        inst.should be_a(Icss::HashOfInteger)
      end
      it 'with nil or "" gives nil; with [] gives []' do
        Icss::Meta::HashSchema.receive({:type => :map, :values => :'int' })
        inst = Icss::HashOfInteger.receive(nil)
        inst.should be_nil
        inst = Icss::HashOfInteger.receive('')
        inst.should be_nil
        inst = Icss::HashOfInteger.receive([])
        inst.should == {}
        inst = Icss::HashOfInteger.receive({})
        inst.should == {}
        inst.should be_a(Icss::HashOfInteger)
      end
      it 'applies the value_factory' do
        Icss::Meta::HashSchema.receive({:type => :map, :values => :'int' })
        inst = Icss::HashOfInteger.receive({ :a => 1, 'b' => 2.0, :c => nil, 'd' => "4.5", :e => "8", 99 => "fnord"})
        inst.should eql({ :a => 1, 'b' => 2, :c => nil, 'd' => 4, :e => 8, 99 => 0})
      end
      it 'warns when I supply "items" not "values"' do
        lambda{
          Icss::Meta::HashSchema.receive({:type => :map, :items => :int })
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe Icss::Meta::EnumSchema do
    [
      {:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]},
      {:type => :enum, :name => 'always_awesome',      :symbols => %w[AWESOME]},
      {:type => :enum, :name => 'jackson.five',        :symbols => [:a, :b, :c]},
    ].each do |schema|
      describe "With #{schema}" do
        before do
          @model_klass = Icss::Meta::EnumSchema.receive(schema)
          @schema_writer = @model_klass._schema
        end
        it 'is a descendent of Enum and of its metatype' do
          @model_klass.should < Symbol
          @model_klass.should be_a Icss::Meta::EnumType
          @model_klass.should be_a Icss::Meta::NamedType
        end
        it 'has symbols' do
          @model_klass.should respond_to(:symbols)
          @schema_writer.symbols.should == schema[:symbols].map(&:to_sym)
        end
        it 'has schema_writer' do
          @schema_writer.type.should  == :enum
          # @schema_writer.should be_valid
          @schema_writer.symbols = []
          # @schema_writer.should_not be_valid
        end
      end
    end

    context '.receive' do
      it 'applies the value_factory' do
        Icss::Meta::EnumSchema.receive({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        inst = Icss::Games::CoinOutcomes.receive('heads')
        inst.should == :heads    ; inst.should be_a(Symbol)
        inst = Icss::Games::CoinOutcomes.receive(:heads)
        inst.should == :heads    ; inst.should be_a(Symbol)
        inst = Icss::Games::CoinOutcomes.receive('sideways')
        inst.should == :sideways ; inst.should be_a(Symbol)
      end
      it 'raises an error on non-included value' do
        Icss::Meta::EnumSchema.receive({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        lambda{ Icss::Games::CoinOutcomes.receive('ace_of_spades') }.should raise_error(ArgumentError, /Cannot receive ace_of_spades: must be one of heads,tails,sideways/)
        Icss::Meta::EnumSchema.receive({:type => :enum, :name => 'herb.caen', :symbols => %w[parseley sage rosemary thyme]})
        lambda{ Icss::Herb::Caen.receive('weed') }.should raise_error(ArgumentError, /Cannot receive weed: must be one of parseley,sage,rosemary,.../)
      end
      it 'raises an error on non-symbolizable value' do
        Icss::Meta::EnumSchema.receive({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        lambda{ Icss::Games::CoinOutcomes.receive(77) }.should raise_error(NoMethodError, /undefined method .to_sym/)
      end
      it 'returns nil on nil/empty string value' do
        Icss::Meta::EnumSchema.receive({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        Icss::Games::CoinOutcomes.receive(nil).should be_nil
        Icss::Games::CoinOutcomes.receive('').should be_nil
        Icss::Games::CoinOutcomes.receive(:"").should be_nil
      end
    end
  end

  describe Icss::Meta::FixedSchema do
    [
      {:type => :fixed, :name => 'geo_feature_category', :size => 1 },
      {:type => :fixed, :name => 'sixteen_bytes_long',   :size => 16 },
    ].each do |schema|
      describe "With #{schema}" do
        before do
          @model_klass = Icss::Meta::FixedSchema.receive(schema)
          @schema_writer = @model_klass._schema
        end
        it 'has schema_writer' do
          @schema_writer.type.should  == :fixed
          # @schema_writer.should be_valid
          @schema_writer.size = nil
          # @schema_writer.should_not be_valid
        end
      end
    end

    context '.receive' do
      it 'applies the value_factory' do
        Icss::Meta::FixedSchema.receive({:type => :fixed, :name => 'sixteen_bytes_long', :size => 16})
        Icss::SixteenBytesLong.receive('123456789_123456').should == '123456789_123456'
      end
      it 'raises an error on too-long value' do
        Icss::Meta::FixedSchema.receive({:type => :fixed, :name => 'sixteen_bytes_long', :size => 16})
        lambda{ Icss::SixteenBytesLong.receive('123456789_1234567') }.should raise_error(ArgumentError, /Wrong size for a fixed-length type sixteen_bytes_long: got 17, not 16/)
      end
      it 'returns nil on nil/empty string value' do
        Icss::Meta::FixedSchema.receive({:type => :fixed, :name => 'sixteen_bytes_long', :size => 16})
        Icss::SixteenBytesLong.receive(nil).should be_nil
        Icss::SixteenBytesLong.receive('').should be_nil
        Icss::SixteenBytesLong.receive(:"").should be_nil
      end
    end
  end

end
