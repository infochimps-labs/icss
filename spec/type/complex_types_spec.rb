require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/receiver_model/active_model_shim'
require 'icss/type/named_type'
require 'icss/type/record_type'
require 'icss/type/type_factory'
require 'icss/type/complex_types'

def compare_methods(klass_a, klass_b, obj_b=nil)
  obj_b ||= klass_b.new
  puts( "%-31s\tobj   \t%s"  % [klass_a.to_s[0..30], (klass_a.new.public_methods             - obj_b.public_methods    ).reject{|m| m.to_s[0..0] == '_' }.inspect]) if klass_a.respond_to?(:new)
  puts( "%-31s\tslfinst\t%s" % [klass_a.to_s[0..30], (klass_a.instance_methods               - klass_b.instance_methods).reject{|m| m.to_s[0..0] == '_' }.inspect])
  puts( "%-31s\tself \t%s"  % [klass_a.to_s[0..30], (klass_a.public_methods                 - klass_b.public_methods  ).reject{|m| m.to_s[0..0] == '_' }.inspect])
  puts( "%-31s\tsgtncl\t%s"  % [klass_a.to_s[0..30], (klass_a.singleton_class.public_methods - klass_b.singleton_class.public_methods).reject{|m| m.to_s[0..0] == '_' }.inspect])
  puts '---------------'
end

def show_anc_chain(klass_a)
  puts ['klass ', klass_a.ancestors                .reject{|kl| kl.name =~ /^(RSpec|PP::ObjectMixin)/ }].join("\t")
  puts ['sgtncl', klass_a.singleton_class.ancestors.reject{|kl| kl.name =~ /^(RSpec|PP::ObjectMixin)/ }].join("\t")
end

class BlankClass
  include Icss::ReceiverModel::ActiveModelShim
end


class FooFactoryClass
  include Icss::ReceiverModel::ActiveModelShim
  include Icss::Meta::RecordType

  field :syms, String, :validates => { :presence => true, :format => { :with => /^\w+$/ } }
  validates :syms, :presence => true, :format => { :with => /^\w+$/ }

  #
  # modify object in place with new typecast values.
  #
  def self.inscribe_schema(mod, hsh={})
    fields.each do |attr, schema|
      if    hsh.has_key?(attr.to_sym) then val = hsh[attr.to_sym]
      elsif hsh.has_key?(attr.to_s)   then val = hsh[attr.to_s]
      else  next ; end
      mod.class_eval{ define_method(attr){ val } }
    end
    mod
  end

end

# module FooFactorySchema
#   include Icss::Meta::RecordType
#
#   field :syms, String, :validates => { :presence => true, :format => { :with => /^\w+$/ } }
#
# end

module FooType
end

class MyHappyEnum
  extend FooType
end

describe 'complex types' do

  describe 'whatever' do
    compare_methods(FooFactoryClass, BlankClass, BlankClass.new)

    compare_methods(FooType, BlankClass, BlankClass.new)

    schema_hsh = { :syms => 'hello' }

    foo_type_instance = FooFactoryClass.new
    foo_type_instance.extend FooType
    p [ foo_type_instance, foo_type_instance.valid?, foo_type_instance.errors ]

    FooFactoryClass.inscribe_schema(FooType, schema_hsh)
    foo_factory_instance = FooFactoryClass.new

    p foo_factory_instance.syms
    foo_factory_instance.extend(FooType)
    p foo_factory_instance.syms
    p [ foo_factory_instance, foo_factory_instance.valid?, foo_factory_instance.errors ]
    p [ foo_type_instance, foo_type_instance.valid?, foo_type_instance.errors ]
  end

  # describe Icss::Meta::ArrayType do
  #   [
  #     {:type => :array, :items => :'this.that.the_other'},
  #     {:type => :array, :items => :'int'     },
  #     {:type => :array, :items => :'core.place'},
  #   ].each do |schema|
  #     it 'round-trips the schema' do
  #       arr_type = Icss::Meta::ArrayType.receive(schema)
  #       arr_type.to_schema.should == schema
  #     end
  #
  #     it 'is a descendent of Array' do
  #       arr_type = Icss::Meta::ArrayType.receive(schema)
  #       p [arr_type]
  #       p [arr_type.valid?, arr_type.errors]
  #       arr_type.should       <  Array
  #       arr_type.new.should be_a(Array)
  #       # compare_methods(arr_type, BlankClass.new, BlankClass.new)
  #     end
  #   end
  #   #        compare_methods(arr_type, Array)
  # end

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

