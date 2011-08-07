require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/receiver_model/active_model_shim'
require 'icss/type'
require 'icss/type/named_type'
require 'icss/type/record_type'
require 'icss/type/complex_types'


def compare_methods(klass_a, klass_b, obj=nil)
  obj_b ||= klass_b.new
  puts( "%-31s\tobj   \t%s" %  [klass_a.to_s[0..30], (klass_a.new.public_methods             - obj_b.public_methods).inspect]) if klass_a.respond_to?(:new)
  puts( "%-31s\tklass \t%s" %  [klass_a.to_s[0..30], (klass_a.public_methods                 - klass_b.public_methods).inspect])
  puts( "%-31s\tsgtncl\t%s" %  [klass_a.to_s[0..30], (klass_a.singleton_class.public_methods - klass_b.singleton_class.public_methods).inspect])
  puts '---------------'
end

def show_anc_chain(klass_a)
  puts ['klass ', klass_a.ancestors                .reject{|kl| kl.name =~ /^(RSpec|PP::ObjectMixin)/ }].join("\t")
  puts ['sgtncl', klass_a.singleton_class.ancestors.reject{|kl| kl.name =~ /^(RSpec|PP::ObjectMixin)/ }].join("\t")
end

def show_method_selfness(klass_a)
  puts "\n", klass_a
  on = (klass_a.respond_to?(:new) ? { 'obj' => klass_a.new } : {})
  on['class']   = klass_a
  on['sgtn_cl'] = klass_a.singleton_class
  [
    :meth_in_class,
    :self_meth_in_class,
    :meth_in_sgtn_cl,
    :self_meth_sgtn_cl,

    :explicit_method_extif,
    :explicit_method_foo,
    :module_meth_extif,
    :module_meth_foo,
    :explicit_method_inclif,
    :module_meth_inclif,
    :module_self_extif,
    :module_self_foo,
    :module_self_inclif,
  ].each do |meth|
    on.each do |kind, obj|
      next unless obj.respond_to?(meth)
      puts( "%-31s\t%-7s\t%-31s\t%-31s\t%s" %  [meth, kind, obj.send(meth)].flatten.map{|x| x.to_s[0..30] } )
    end
  end
end

module BlankModule
end

class BlankClass
end

module Icss::Meta
  module TypeFactory
    def self.receive(*args)
      super(*args)
    end
  end
end

# [Icss::Meta::FooBar, Icss::Meta::RecordType, Icss::Meta::NamedType, Icss::Meta::Type, Object, RSpec::Mocks::Methods, PP::ObjectMixin, RSpec::Core::SharedExampleGroup, RSpec::Core::DSL, Kernel, BasicObject]
# [Icss::Meta::FooBar, Icss::Meta::RecordType, Icss::Meta::NamedType, Icss::Meta::Type, Object, RSpec::Mocks::Methods, PP::ObjectMixin, RSpec::Core::SharedExampleGroup, RSpec::Core::DSL, Kernel, BasicObject]

# describe 'bootstrapping' do
#   it 'does' do
#     p [Icss::Meta::ArrayType::Schema.public_methods   - BlankModule.public_methods]
#     p [Icss::Meta::ArrayType::Schema.instance_methods - BlankModule.instance_methods]
#     puts '---------'
#     p [Icss::Meta::ArrayType.public_methods           - BlankModule.public_methods]
#     p [Icss::Meta::ArrayType.instance_methods         - BlankModule.instance_methods]
#     p [Icss::Meta::ArrayType::Schema.fullname,          Icss::Meta::ArrayType::Schema.to_schema]
#     puts '---------'
#     p [Icss::Meta::FooBar.public_methods            - BlankClass.public_methods]
#     p [Icss::Meta::FooBar.instance_methods          - BlankClass.instance_methods]
#     puts '---------'
#     p Icss::Meta::FooBar.ancestors
#     p Icss::Meta::FooBar.singleton_class.ancestors
#     p [Icss::Meta::FooBar.to_schema]
#     puts '-----'
#   end
# end

describe 'complex types' do

  describe Icss::Meta::ArrayType do
    [
      {:type => :array, :items => :'this.that.the_other'},
      {:type => :array, :items => :'int'     },
      {:type => :array, :items => :'core.place'},
    ].each do |schema|
      it 'round-trips the schema' do
        arr_type = Icss::Meta::ArrayType.receive(schema)
        arr_type.to_schema.should == schema
      end

      it 'is a descendent of Array' do
        arr_type = Icss::Meta::ArrayType.receive(schema)
        arr_type.should       <  Array
        arr_type.new.should be_a(Array)
      end
    end
    #        compare_methods(arr_type, Array)
  end

  describe Icss::Meta::HashType do
    [
      {:type => :map, :values => :'this.that.the_other'},
      {:type => :map, :values => :'int'     },
      {:type => :map, :values => :'core.place'},
    ].each do |schema|
      it 'round-trips the schema' do
        hsh_type = Icss::Meta::HashType.receive(schema)
        hsh_type.to_schema.should == schema
      end

      it 'is a descendent of Hash' do
        hsh_type = Icss::Meta::HashType.receive(schema)
        hsh_type.should       <  Hash
        hsh_type.new.should be_a(Hash)
        compare_methods(hsh_type, Hash)
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
