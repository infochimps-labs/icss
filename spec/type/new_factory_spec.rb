require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss'
require 'icss/type/new_factory'

describe Icss::Meta::BaseType do
  before do
    @test_protocol_hsh = YAML.load(File.open(File.expand_path(File.dirname(__FILE__) + '/../test_icss.yaml')))
    @simple_record_hsh = @test_protocol_hsh['types'].first
  end

  it 'loads from a hash' do
    Icss::Meta::BaseType.receive!(@simple_record_hsh)
    p [Icss::Meta::BaseType, Icss::Meta::BaseType.fields]
    Icss::Meta::BaseType.fields.length.should == 3
    ref_field = Icss::Meta::BaseType.fields.first
    ref_field.name.should == 'my_happy_string'
    ref_field.doc.should  =~ /field 1/
    ref_field.type.name.should == :string
  end

  it 'makes a meta type' do
    k = Icss::Meta::TypeFactory.make('icss.simple_type')
    meta_type = Icss::RecordType.receive(@simple_record_hsh)
    p meta_type
    k.class_eval{ include Receiver }
    meta_type.decorate_with_receivers(k)
    meta_type.decorate_with_conveniences(k)
    meta_type.decorate_with_validators(k)
    p [k.fields, k.receiver_attr_names]
  end
 

  # it "has the *class* attributes of an avro record type" do
  #   [:name, :doc, :fields, :is_a, ]
  # end
  #
  # it "is an Icss::Meta::NamedType, an Icss::Meta::Type, and an Icss::Base" do
  #   Icss::Meta::RecordType.should < Icss::Meta::NamedType
  #   Icss::Meta::RecordType.should < Icss::Meta::Type
  #   Icss::Meta::RecordType.should < Icss::Base
  # end 

end



# describe Icss::Entity do
#
# end
 

