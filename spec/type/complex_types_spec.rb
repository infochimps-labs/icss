require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
# require 'icss/type/named_type'
# require 'icss/type/record_type'
require 'icss/type/field_decorators'
require 'icss/type/receiver_decorators'
#require 'icss/type/type_factory'
require 'icss/type/complex_types'

describe 'complex types' do

  describe Icss::Meta::ArrayType do

    it 'whatever' do
      p [Icss::Meta::ArrayType.public_methods     - Class.public_methods]
      p [Icss::Meta::ArrayType.public_methods     - Array.public_methods    ]
      p [Icss::Meta::ArrayType.new.public_methods - Array.new.public_methods]

      p Icss::Meta::ArrayType.to_schema

      k = Icss::Meta::ArrayType.make({ :type => 'array', :items => 'int' })

      # FooType.extend(Icss::Meta::NamedType)
      #p [FooType.namespace, FooType.typename, FooType.public_methods - Class.public_methods]
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
end
