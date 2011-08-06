require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/type/named_type'
require 'icss/type/record_type'
require 'icss/type/field_decorators'
require 'icss/type/type_factory'
require 'icss/type/complex_types'

describe 'complex types' do

  describe Icss::Type do

    it 'whatever' do
      p [Icss::Type::EnumType.public_methods - Module.public_methods]
      p [Icss::Type::EnumType.public_methods - Class.public_methods]

      p Icss::Type::EnumType.to_schema

      # FooType.extend(Icss::Type::NamedType)
      #p [FooType.namespace, FooType.typename, FooType.public_methods - Class.public_methods]
    end

    context Icss::Type::UnionType do
      it 'receives simple unions' do
        uu = Icss::Type::UnionType.receive([:int, :string])
        uu.declaration_flavors.should == [:primitive, :primitive]
        uu.to_schema.should == [:int, :string]
      end

      it 'receives complex unions' do
        uu = Icss::Type::UnionType.receive([ 'boolean', 'double',
            {'type' => 'array', 'items' => 'bytes'}])
        uu.declaration_flavors.should == [:primitive, :primitive]
        uu.to_schema.should == [:int, :string]
      end

    end
  end
end
