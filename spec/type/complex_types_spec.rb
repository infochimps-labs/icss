require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/receiver_model/active_model_shim'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/named_schema'
require 'icss/type/has_fields'
require 'icss/type/named_schema'
require 'icss/type/record_type'
require 'icss/type/complex_types'
require 'icss/type/type_factory'

module Icss
  module This
    module That
      class TheOther
        extend Icss::Meta::NamedSchema
        def self.receive(*args) self.new() end
      end
    end
  end
  Blinken = 7
  class Entity
    extend Icss::Meta::NamedSchema
    def self.receive(*args) self.new() end
  end
  module Core
    class Thing < Entity
    end
  end
end

describe 'complex types' do
  before do
    [ "Icss::ArrayOfInt",            "Icss::ArrayOfCore_Thing",           "Icss::ArrayOfThis_That_TheOther",
      "Icss::Meta::ArrayOfIntType", "Icss::Meta::ArrayOfCore_ThingType", "Icss::Meta::ArrayOfThis_That_TheOtherType",
    ].each do |const_name|
      scopes = const_name.split(/::/); cc = scopes.pop ; mod = scopes.join('::').constantize;
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
        inst.should be_a(Icss::ArrayOfInt)
      end
      it 'applies the item_factory' do
        Icss::Meta::ArraySchema::Writer.receive_schema({:type => :array, :items => :'int' })
        inst = Icss::ArrayOfInt.receive([1, 2.0, nil, "4.5", "8", "fnord"])
        inst.should eql([1, 2, nil, 4, 8, 0])  # (1 == 1.0) is true but 1.eql?(1.0) is false
      end
    end

  end

  # describe Icss::Meta::HashType do
  #   [
  #     {:type => :map, :values => :'this.that.the_other'},
  #     {:type => :map, :values => :'int'     },
  #     {:type => :map, :values => :'core.place'},
  #   ].each do |schema|
  #     it 'round-trips the schema' do
  #       hsh_type = Icss::Meta::HashType.receive(schema)
  #       hsh_type.to_schema.should == schema
  #       compare_methods(hsh_type, Hash, Hash.new)
  #     end
  #
  #     it 'is a descendent of Hash' do
  #       hsh_type = Icss::Meta::HashType.receive(schema)
  #       hsh_type.should       <  Hash
  #       hsh_type.new.should be_a(Hash)
  #     end
  #   end
  # end

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
