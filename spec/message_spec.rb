require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'icss'
require ENV.root_path('spec/support/icss_test_helper')
include IcssTestHelper


describe Icss::Meta::Message do
  before(:each) do
    IcssTestHelper.remove_icss_constants('Poppa', 'Smurfette', 'Handy', 'Hefty')
    class Icss::Poppa < Icss::SmurfRecord
      field :smurfiness, Integer
    end
    class Icss::Smurfette < Icss::SmurfRecord
      field :blondness, Integer
    end
    class Icss::Handy < Icss::SmurfRecord
      field :smurfiness, Integer
      field :tool,       Symbol, :default => :smurfwrench
      field :weapon,     Symbol, :default => :smurfthrower
    end
  end

  let(:smurfy_message_hsh){
    { :name     => 'dance',
      :doc      => 'this is how we dance',
      :request  => [{ :name => 'params', :type => Icss::Poppa },],
      :response => Icss::Smurfette,
      :errors   => ['oops']
    } }
  let(:smurfy_message){ Icss::Meta::Message.receive(smurfy_message_hsh) }

  let(:fun_protocol_hsh){
    { :protocol => 'smurf.village.fun',
      :messages => { :dance => smurfy_message_hsh } } }
  let(:fun_protocol){ Icss::Meta::Protocol.receive(fun_protocol_hsh) }

  describe 'basic behavior' do
    subject{ smurfy_message }
    its(:name){                should == 'dance' }
    its('request.first.name'){ should == :params }
    its('request.first.type'){ should == Icss::Poppa }
    its(:params_type){         should == Icss::Poppa }
    its(:response){            should == Icss::Smurfette }
    its(:errors){              should == ['oops'] }
  end

  describe 'knows its protocol' do
    let(:dance){ fun_protocol.messages[:dance] }
    subject{ dance }
    it{ should be_a(Icss::Meta::Message) }
    it 'knows its protocol' do
      dance.protocol.should == fun_protocol
    end
    its(:fullname){ should == 'smurf.village.fun.dance' }
    its(:path){     should == 'smurf/village/fun/dance' }
  end

  describe '#to_hash' do
    it 'correctly' do
      smurfy_message.to_hash.should == {
        :request  => ["poppa"],
        :response => "smurfette",
        :doc      => "this is how we dance",
        :errors   => ["oops"]
      }
    end
  end

  describe 'reference tracking' do
    {
      'simple type' => 'string',
      'named ref'   => 'poppa',
      'class'       => Icss::SmurfRecord,
    }.each do |ref_type, ref|
      it "is a reference if it receives a #{ref_type}" do
        smurfy_message_hsh[:request].first[:type] = ref
        msg = Icss::Meta::Message.receive(smurfy_message_hsh)
        msg.request.map{|r| r.is_reference? }.should == [true]
      end
    end
    {
      'record schema' => {:name => 'hefty', :type => :record, :fields => [:name => :strength, :type => :float]},
      'array schema'  => {:type => :array,  :items  => :poppa},
      'hash schema'   => {:type => :map,    :values => :smurfette},
    }.each do |ref_type, ref|
      it "is not a reference if it receives a string" do
        smurfy_message_hsh[:request].first[:type] = ref
        msg = Icss::Meta::Message.receive(smurfy_message_hsh)
        msg.request.map{|r| r.is_reference? }.should == [nil]
      end
    end

  end
end
