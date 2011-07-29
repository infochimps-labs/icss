require 'icss'

def test_icss
  YAML.load File.read(File.join(File.dir_name(__FILE__), 'test_icss.yaml'))
end

# This is only the coverage associated with the Great Schematizing. It still
# needs spec coverage in other areas.
describe Icss::Protocol do
  before :each do
    @icss = Icss::Protocol.receive test_icss
  end

  context "receiving referenced types" do

    it "should be able to identify the referenced type specified"

    it "should add the referenced type to the array of types for this protocol"

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

  context "Icss::Klasses" do

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
