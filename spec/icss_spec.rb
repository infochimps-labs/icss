require 'icss'

def test_icss
  YAML.load File.read(File.join(File.dirname(__FILE__), 'test_icss.yaml'))
end

describe Icss::Protocol do
  before :each do
    @icss = Icss::Protocol.receive test_icss
  end

  it "should be able to receive valid YAML files" do
    @icss.should be_a Icss::Protocol
  end

  context "receiving referenced types" do

    it "should be able to identify the referenced type specified" do
      ref_type  = @icss.types.select{ |t| t.name == 'test_ref_type' }.first
      ref_field = ref_type.fields.select{ |f| f.name == 'ref_field' }.first
      ref_field.to_hash.should == {
        :name => "ref_field",
        :doc  => "A field that references a type.",
        :type => "place"
      }
    end

    it "should add the referenced type to the array of types for this protocol" do
      puts Icss::Type::DERIVED_TYPES.keys.inspect
      @icss.types.map(&:name).should include 'place'
    end

  end

  context "receiving is_a" do

    it "should populate the fields array with the referenced type's fields"

    it "should allow additional field definitions to be added after the receive"

    it "should override referenced fields when a field is defined with the same name"

  end

  context "receiving identifier" do

    it "should be able to return all field definitions specified as identifiers"

  end

  context "receiving domain_id" do

    it "should be able to return the field definition specified as the domain_id"

  end

  context "receiving validates" do

    it "should be able validate the received values using the specified active model validators"

  end

  context "Icss::Klass" do

    it "should be able to return its values with dotted accessors"

  end

  context "transformation" do

    it " should be able to transform itself into a GeoJson object"

    context "receiving aspects" do

      it "should be able to generate a class form its apect's typing"

      it "should receive the aspect's properties first"

      it "should receive the original Icss::Klass properties"

      it "should receive the original Icss::Klass as an aspect, inlcuding left over properties"

    end

  end

end
