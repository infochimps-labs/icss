require 'rubygems'
require 'rspec'
require 'icss'

def template_icss
  return <<EOS
---
namespace: foo.bar
protocol: baz

data_assets:
- name: test_data_asset
  location: data/test_data.tsv
  type: test_data_record

messages:
  search:
    doc: A testable template message
    request:
    - name: test_request
      type: test_request_record
    response: test_data_record
    samples:
    - request:
      - first_param: foo
        second_param: bar

targets:
  catalog:
  - name: test_catalog_entry
    title: Test Icss
    description: This is a template Icss to test the error handling of the Icss library.
    tags:
    - test
    - icss
    - template
    messages:
    - search
    packages:
    - data_assets:
      - test_data_asset

types:
- name: test_request_record
  doc: A template request record
  type: record
  fields:
  - name: first_param
    doc: The first test parameter
    type: string
  - name: second param
    doc: The second test parameter
    type: string

- name: test_complex_data
  doc: A template complex data type
  type: record
  fields:
  - name: field_one
    doc: A simple field for a complex data type
    type: string
  - name: field_two
    doc: Another simple field for a complex data type
    type: string

- name: test_data_record
  doc: A template data record
  type: record
  fields:
  - name: simple_data
    doc: A simple piece of data
    type: int
  - name: complex_data
    doc: A complex piece of data
    type: test_complex_data

EOS
end

describe "Icss::Meta::Protocol validations" do
  before :each do
    @template = YAML.load(template_icss)
  end

  it "should be able to receive a correctly formatted template Icss" do
    lambda { @icss =Icss::Meta::Protocol.receive @template }.should_not raise_error
    @icss.errors.should be_empty
  end

  it "should contain keys for all fields even if not included in the Icss file" do
    @icss = Icss::Meta::Protocol.receive @template
    @icss.keys.map { |k| k.to_s }.sort.should == (@template.keys | ['code_assets']).sort
  end

  it "should generate an error when the namespace is formatted incorrectly" do
    @template['namespace'] = '$bad_namespace'
    Icss::Meta::Protocol.receive(@template).errors.keys.should == [:namespace]
  end

  it "should generate an error when the protocol is formatted incorrectly" do
    @template['protocol'] = '$bad_protocol'
    Icss::Meta::Protocol.receive(@template).errors.keys.should == [:protocol]
  end

  # context "Catalog Target" do
  #
  #   it "should generate an error when an undefined data_asset is specified" do
  #     @template['targets']['catalog'].first['packages'].first['data_assets'] = ['fake_data_asset']
  #     Icss::Meta::Protocol.receive(@template).errors.keys.should == [:catalog]
  #   end
  #
  #   it "should generate an error when an undefined message name is specified" do
  #     @template['targets']['catalog'].first['messages'] = ['fake_message']
  #     Icss::Meta::Protocol.receive(@template).errors.keys.should == [:catalog]
  #   end
  #
  # end
  #
  # context "Data Assets" do
  #
  #   it "should generate an error when an asset's type is undefined" do
  #     @template['data_assets'].first['type'] = 'fake_data_asset'
  #     Icss::Meta::Protocol.receive(@template).errors.keys.should == [:data_assets]
  #   end
  #
  # end
  #
  # context "Messages" do
  #
  #   it "should generate an error when a message's request type is undefined" do
  #     @template['messages']['search']['request'].first['type'] = 'fake_request_type'
  #     Icss::Meta::Protocol.receive(@template).errors.keys.should == [:messages]
  #   end
  #
  #   it "should generate an error when a message's response type is undefined" do
  #     @template['messages']['search']['response'] = 'fake_response_type'
  #     Icss::Meta::Protocol.receive(@template).errors.keys.should == [:messages]
  #   end
  #
  #   it "should generate an error when a message's sample request types do not match the request record" do
  #     @template['messages']['search']['samples'].first['request'] = [{ 'foo' => 'bar' }]
  #     Icss::Meta::Protocol.receive(@template).errors.keys.should == [:messages]
  #   end
  #
  # end

  context "Types" do

    it "should raise an error when an bad type definition is given for a specific type" do
      @template['types'].push({
          'name' => 'fake_type_record',
          'type' => 'fake'
        })
      lambda{ Icss::Meta::Protocol.receive(@template) }.should raise_error(NameError, /uninitialized.*Fake/)
    end

    it "should generate an error when an undefined type definition is given for a specific field" do
      @template['types'].push({
          'name' => 'fake_type_record',
          'type' => 'record',
          'fields' => [{
              'name' => 'fake_field',
              'type' => 'fake_type'
            }]
        })
      lambda{ Icss::Meta::Protocol.receive(@template) }.should raise_error(NameError, /uninitialized.*FakeType/)
    end

  end

end
