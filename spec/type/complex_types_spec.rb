require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
# require 'icss/type/named_type'
# require 'icss/type/record_type'
require 'icss/type/field_decorators'
require 'icss/type/receiver_decorators'
#require 'icss/type/type_factory'
require 'icss/type/complex_types'


def compare_methods(klass_a, klass_b)
  puts( "%-31s\tobj   \t%s" %  [klass_a.to_s[0..30], (klass_a.new.public_methods             - Object.new.public_methods).inspect]) if klass_a.respond_to?(:new)
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

describe 'complex types' do

  describe Icss::Meta::ArrayType do
    it 'whatever' do
      compare_methods(Icss::Meta::ArrayType, Class)
      compare_methods(Icss::Meta::ArrayType, Array)

      # k = Icss::Meta::ArrayType.receive({ :type => 'array', :items => 'int' })
      #
      # compare_methods(k, Array)
      #
      #
      # p Icss::Meta::ArrayType.to_schema
      #
      # p Icss::Meta.class
      # p Icss::Meta.singleton_class

      # FooType.extend(Icss::Meta::NamedType)
      #p [FooType.namespace, FooType.typename, FooType - Class]
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
