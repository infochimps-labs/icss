require 'icss'

def test_icss
  return <<EOF
---
namespace: foo.bar
protocol: baz
types:

- name: test_ref_type
  doc: A record to test referenced types.
  type: record
  fields:
  - name: ref_field
    doc: A field that references a type.
    type: icss.core.place

- name: test_is_a_method
  doc: A record to test the is_a method.
  type: record
  is_a:
  - icss.core.place
  fields:
  - name: additional_field
    doc: A field to test the ability to add additional fields with the is_a method.
    type: int
  - name: description
    doc: A field to test the override of is_a properties.
    type: string

- name: test_identifiers
  doc: A record to test the identifier methods.
  type: record
  domain_id: ssn
  fields:
  - name: name
    doc: A field that is NOT an identifier.
    type: string
  - name: age
    doc: A field that IS an identifier.
    type: int
    identifier: true
  - name: ssn
    doc: A field to test the domain_id.
    type: int
    identifier: true

- name: test_validators
  doc: A record to test validations.
  type: record
  fields:
  - name: homepage
    doc: A field needing formatting validation.
    type: string
    validates:
      format:
        with: "/[\w+]\.[com?|org|net]/"

EOF
end

# This is only the coverage associated with the Great Schematizing. It still
# needs spec coverage in other areas.
describe Icss::Protocol do

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
