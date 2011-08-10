require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/receiver_model/active_model_shim'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/named_schema'
require 'icss/type/has_fields'
require 'icss/type/named_schema'
require 'icss/type/record_type'
# require 'icss/type/complex_types'
require 'icss/type/type_factory'

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

module Icss
  module Meta

    # -------------------------------------------------------------------------
    #
    # Container Types (array, map and union)
    #

    #
    # ArraySchema describes an Avro Array type.
    #
    # Arrays use the type name "array" and support a single attribute:
    #
    # * items: the schema of the array's items.
    #
    # @example, an array of strings is declared with:
    #
    #     {"type": "array", "items": "string"}
    #
    module ArraySchema
      def receive(raw)
        return nil if raw.nil? || (raw == "")
        self.new( raw.map{|raw_item| item_factory.receive(raw_item) } )
      end

      def to_schema()
        (defined?(super) ? super() : {}).merge({ :type => self.type, :items => self.items })
      end

      class Writer
        extend Icss::Meta::NamedSchema
        include Icss::Meta::RecordType
        include Icss::ReceiverModel::ActiveModelShim
        #
        field :type,         Symbol, :validates => { :format => { :with => /^array$/ } }
        field :items,        Object
        field :item_factory, Icss::Meta::TypeFactory
        after_receive{|hsh| self.receive_item_factory(self.items) }
        #
        validates :type,  :presence => true, :format => { :with => /^array$/ }
        validates :items, :presence => true

        def self.name_for_klass(schema)
          return unless schema[:items].respond_to?(:to_sym)
          slug = Icss::Meta::Type.klassname_for(schema[:items].to_sym).gsub(/^:*Icss:+/, '').gsub(/:+/, '_')
          "ArrayOf#{slug}"
        end

        # retrieve the
        def self.receive_schema(schema)
          schema_obj = self.receive(schema)
          type_klass = Icss::Meta::NamedSchema.get_type_klass( name_for_klass(schema),  Array)
          type_klass.class_eval{ extend(::Icss::Meta::ArraySchema) }
          inscribe_schema(schema_obj, type_klass.singleton_class)
          type_klass
        end
      end
    end

    #
    # Describes an Avro Enum type.
    #
    # Enums use the type name "enum" and support the following attributes:
    #
    # name:       a string providing the name of the enum (required).
    # namespace:  a string that qualifies the name;
    # doc:        a string providing documentation to the user of this schema (optional).
    # symbols:    an array, listing symbols, as strings or ruby symbols (required). All
    #             symbols in an enum must be unique; duplicates are prohibited.
    #
    # For example, playing card suits might be defined with:
    #
    # { "type": "enum",
    #   "name": "Suit",
    #   "symbols" : ["SPADES", "HEARTS", "DIAMONDS", "CLUBS"]
    # }
    #
    class EnumSchema
      def receive(raw)
        return nil if raw.nil? || (raw == "")
        obj = self.new
        raw.each{|rk,rv| obj[rk] = value_factory.receive(rv) }
        obj
      end

      def to_schema()
        (defined?(super) ? super() : {}).merge({ :type => self.type, :values => self.values })
      end

      class Writer
        extend Icss::Meta::NamedSchema
        include Icss::Meta::RecordType
        include Icss::ReceiverModel::ActiveModelShim
        #
        field :type,         Symbol, :validates => { :format => { :with => /^enum$/ } }
        field :name,         Symbol, :validates => { :format => { :with => /^enum$/ } }
        field :symbols,      Object # :array,  :items => Symbol, :required => true, :default => []
        validates :type,    :presence => true, :format => { :with => /^map$/ }
        validates :name,    :presence => true
        validates :symbols, :presence => true

        # retrieve the
        def self.receive_schema(schema)
          schema_obj = self.receive(schema)
          type_klass = Icss::Meta::NamedSchema.get_type_klass( name_for_klass(schema),  Hash )
          type_klass.class_eval{ extend(::Icss::Meta::HashSchema) }
          inscribe_schema(schema_obj, type_klass.singleton_class)
          type_klass
        end
      end
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

  # describe Icss::Meta::HashSchema::Writer do
  #   [
  #     [{:type => :map, :values => :'this.that.the_other'}, Icss::This::That::TheOther, ],
  #     [{:type => :map, :values => :'int'     },            Integer,           ],
  #     [{:type => :map, :values => :'core.thing'},          Icss::Core::Thing, ],
  #   ].each do |schema, expected_value_factory|
  #     describe "With #{schema}" do
  #       before do
  #         @arr_klass = Icss::Meta::HashSchema::Writer.receive_schema(schema)
  #         @arr_schema_writer = @arr_klass._schema
  #       end
  #
  #       it 'round-trips the schema' do
  #         @arr_klass.to_schema.should == schema
  #       end
  #
  #       it 'is a descendent of Hash and of its metatype' do
  #         @arr_klass.should < Hash
  #         @arr_klass.should be_a Icss::Meta::HashSchema
  #       end
  #
  #       it 'has values and an value_factory' do
  #         @arr_klass.should respond_to(:values)
  #         @arr_klass.values.should == schema[:values]
  #         @arr_klass.value_factory.should == expected_value_factory
  #       end
  #
  #       it 'has schema_writer' do
  #         @arr_schema_writer.type.should  == :map
  #         @arr_schema_writer.values.should == schema[:values]
  #         @arr_schema_writer.should be_valid
  #         @arr_schema_writer.type = :YO_ADRIAN
  #         @arr_schema_writer.should_not be_valid
  #       end
  #     end
  #   end
  #
  #   context '.receive' do
  #     it 'generates an instance of the type' do
  #       Icss::Meta::HashSchema::Writer.receive_schema({:type => :map, :values => :'int' })
  #       inst = Icss::HashOfInt.receive([1, 2.0, nil, "4.5", "8", "fnord"])
  #       inst.should be_a(Hash)
  #       inst.should be_a(Icss::HashOfInt)
  #     end
  #     it 'with nil or "" gives nil; with [] gives []' do
  #       Icss::Meta::HashSchema::Writer.receive_schema({:type => :map, :values => :'int' })
  #       inst = Icss::HashOfInt.receive(nil)
  #       inst.should be_nil
  #       inst = Icss::HashOfInt.receive('')
  #       inst.should be_nil
  #       inst = Icss::HashOfInt.receive([])
  #       inst.should == {}
  #       inst = Icss::HashOfInt.receive({})
  #       inst.should == {}
  #       inst.should be_a(Icss::HashOfInt)
  #     end
  #     it 'applies the value_factory' do
  #       Icss::Meta::HashSchema::Writer.receive_schema({:type => :map, :values => :'int' })
  #       inst = Icss::HashOfInt.receive({ :a => 1, 'b' => 2.0, :c => nil, 'd' => "4.5", :e => "8", 99 => "fnord"})
  #       inst.should eql({ :a => 1, 'b' => 2, :c => nil, 'd' => 4, :e => 8, 99 => 0})
  #     end
  #   end
  # end

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
          @arr_klass.to_schema.should == schema
        end

        it 'is a descendent of Enum and of its metatype' do
          @arr_klass.should < Enum
          @arr_klass.should be_a Icss::Meta::EnumSchema
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
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :map, :values => :'int' })
        inst = Icss::EnumOfInt.receive([1, 2.0, nil, "4.5", "8", "fnord"])
        inst.should be_a(Enum)
        inst.should be_a(Icss::EnumOfInt)
      end
      it 'with nil or "" gives nil; with [] gives []' do
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :map, :values => :'int' })
        inst = Icss::EnumOfInt.receive(nil)
        inst.should be_nil
        inst = Icss::EnumOfInt.receive('')
        inst.should be_nil
        inst = Icss::EnumOfInt.receive([])
        inst.should == {}
        inst = Icss::EnumOfInt.receive({})
        inst.should == {}
        inst.should be_a(Icss::EnumOfInt)
      end
      it 'applies the value_factory' do
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        inst = Icss::Games::CoinOutcomes.receive('heads')
        inst.should == :heads    ; inst.should be_a(Symbol)
        inst = Icss::Games::CoinOutcomes.receive(:heads)
        inst.should == :heads    ; inst.should be_a(Symbol)
        inst = Icss::Games::CoinOutcomes.receive('sideways')
        inst.should == :sideways ; inst.should be_a(Symbol)
        inst = Icss::Games::CoinOutcomes.receive('ace_of_spades')
      end
      it 'raises an error on non-included value' do
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        lambda{ Icss::Games::CoinOutcomes.receive('ace_of_spades') }.should raise_error(ArgumentError, /enum cannot receive ace_of_spades: must be one of \[heads,tails,sideways\]/)
      end
      it 'raises an error on non-symbolizable value' do
        Icss::Meta::EnumSchema::Writer.receive_schema({:type => :enum, :name => 'games.coin_outcomes', :symbols => %w[heads tails sideways]})
        lambda{ Icss::Games::CoinOutcomes.receive(77) }.should raise_error(ArgumentError, /enum cannot receive ace_of_spades: must be one of \[heads,tails,sideways\]/)
        lambda{ Icss::Games::CoinOutcomes.receive([]) }.should raise_error(ArgumentError, /enum cannot receive ace_of_spades: must be one of \[heads,tails,sideways\]/)
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
