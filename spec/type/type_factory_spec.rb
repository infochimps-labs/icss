require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/named_type'
# require 'icss/type/complex_types'
require 'icss/type/record_type'
require 'icss/type/field_decorators'
require 'icss/type/type_factory'

describe Icss::Type::TypeFactory do
  module EnumType
    include Icss::Type::NamedType
    extend Icss::Type::RecordType::FieldDecorators
    field :symbols, Array, :of => String, :required => true, :default => []
    def schema_hash
        (defined?(super) ? super : {}).merge({ :symbols   => symbols })
    end
  end

  it 'whatever' do
    p [EnumType.public_methods - Module.public_methods]
    p [EnumType.public_methods - Class.public_methods]

    p EnumType.schema_hash
    # FooType.extend(Icss::Type::NamedType)
    #p [FooType.namespace, FooType.typename, FooType.public_methods - Class.public_methods]
  end

  # module Icss
  #   module This
  #     module That
  #       class TheOther
  #       end
  #     end
  #   end
  #   Blinken = 7
  # end
  #
  # context '.receive' do
  #   it 'on a primitive type' do
  #     Icss::Type::PRIMITIVE_TYPES.each do |al, kl|
  #       Icss::Type::TypeFactory.receive(al).should == kl
  #     end
  #     Icss::Type::TypeFactory.receive('string').should == String
  #     Icss::Type::TypeFactory.receive('int'   ).should == Integer
  #   end
  #   it 'on a simple type' do
  #     Icss::Type::SIMPLE_TYPES.each do |al, kl|
  #       Icss::Type::TypeFactory.receive(al).should == kl
  #     end
  #   end
  #   it 'on a named type' do
  #     p [ Icss::This::That::TheOther.ancestors, (Icss::This::That::TheOther < Icss::Type::RecordType) ]
  #     Icss::Type::TypeFactory.receive('this.that.the_other').should == Icss::This::That::TheOther
  #     Icss::Type::TypeFactory.receive('Icss::This::That::TheOther').should == Icss::This::That::TheOther
  #   end
  #   it 'on a union type (array)' do
  #     uu = Icss::Type::TypeFactory.receive([ 'Icss::This::That::TheOther', Integer ])
  #     uu.should be_a(Icss::Type::UnionType)
  #   end
  # end

  # context '.ensure_module_scope' do
  #   it 'adds a new child when parents exist' do
  #     Icss::This::That.should_not be_const_defined(:AlsoThis)
  #     new_module = Icss::Type::TypeFactory.get_module_scope(%w[Icss This That AlsoThis])
  #     new_module.name.should == 'Icss::This::That::AlsoThis'
  #     Icss::This::That::AlsoThis.class.should == Module
  #     Icss::This::That.send(:remove_const, :AlsoThis)
  #   end
  #   it 'adds parents as necessary' do
  #     Icss.should_not be_const_defined(:Winken)
  #     new_module = Icss::Type::TypeFactory.get_module_scope(%w[Icss Winken Blinken Nod])
  #     new_module.name.should == 'Icss::Winken::Blinken::Nod'
  #     Icss::Winken::Blinken::Nod.class.should == Module
  #     Icss::Winken::Blinken.class.should      == Module
  #     Icss::Winken.class.should               == Module
  #     Icss.send(:remove_const, :Winken)
  #   end
  # end
  #
  # context '.make' do
  #   it 'succeeds when the class already exists' do
  #     klass, meta_module = Icss::Type::TypeFactory.make('this.that.the_other')
  #     klass.should be_a(Class)
  #     klass.name.should == 'Icss::This::That::TheOther'
  #     meta_module.should be_a(Module)
  #     meta_module.name.should == 'Icss::Type::This::That::TheOtherType'
  #   end
  #   it 'succeeds when the class does not already exist' do
  #     Icss.should_not be_const_defined(:YourMom)
  #     klass, meta_module = Icss::Type::TypeFactory.make('your_mom.wears.combat_boots')
  #     klass.name.should == 'Icss::YourMom::Wears::CombatBoots'
  #     Icss::Type::YourMom::Wears::CombatBootsType.class.should == Module
  #     Icss::Type::YourMom::Wears.class.should                  == Module
  #     Icss::YourMom::Wears::CombatBoots.class.should           == Class
  #     Icss::YourMom::Wears.class.should                        == Module
  #     Icss::Type.send(:remove_const, :YourMom)
  #     Icss.send(:remove_const, :YourMom)
  #   end
  #   it 'includes its meta type as a module' do
  #     Icss.should_not be_const_defined(:YourMom)
  #     klass, meta_module = Icss::Type::TypeFactory.make('your_mom.wears.combat_boots')
  #     # klass.should < Icss::Type::YourMom::Wears::CombatBootsType
  #   end
  # end

end

# describe Icss::Type do
#   before do
#     @test_protocol_hsh = YAML.load(File.open(File.expand_path(File.dirname(__FILE__) + '/../test_icss.yaml')))
#     @simple_record_hsh = @test_protocol_hsh['types'].first
#   end
#
#   it 'loads from a hash' do
#     Icss::Type::BaseType.receive!(@simple_record_hsh)
#     p [Icss::Type::BaseType, Icss::Type::BaseType.fields]
#     Icss::Type::BaseType.fields.length.should == 3
#     ref_field = Icss::Type::BaseType.fields.first
#     ref_field.name.should == 'my_happy_string'
#     ref_field.doc.should  =~ /field 1/
#     ref_field.type.name.should == :string
#   end
#
#   it 'makes a meta type' do
#     k = Icss::Type::TypeFactory.make('icss.simple_type')
#     meta_type = Icss::RecordType.receive(@simple_record_hsh)
#     p meta_type
#     k.class_eval{ include Receiver }
#     meta_type.decorate_with_receivers(k)
#     meta_type.decorate_with_conveniences(k)
#     meta_type.decorate_with_validators(k)
#     p [k.fields, k.receiver_attr_names]
#   end
#
#
#   # it "has the *class* attributes of an avro record type" do
#   #   [:name, :doc, :fields, :is_a, ]
#   # end
#   #
#   # it "is an Icss::Type::NamedType, an Icss::Type::Type, and an Icss::Base" do
#   #   Icss::Type::RecordType.should < Icss::Type::NamedType
#   #   Icss::Type::RecordType.should < Icss::Type::Type
#   #   Icss::Type::RecordType.should < Icss::Base
#   # end
#
# end

# context 'is_a (inheritance)' do
#     it 'knows its direct Icss superclass'
#     it 'knows its Icss mixin classes'
#   end
#
#   context 'synthesizing' do
#     it 'has a Meta model to '
#   end

