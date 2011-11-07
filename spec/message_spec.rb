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
    class Icss::Handy < Icss::Poppa
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

  # ===========================================================================
  #
  # Message samples
  #
  describe Icss::Meta::MessageSample do
    let(:samp_msg_hsh){
      {
        :name         => 'lambada',
        :request      => [{ :smurfiness => 1, :blondness => 12 }],
        :response_hsh =>  { :smurfiness => 1, :tool => :pipesmurf, :weapon => :broadsmurf },
      }
    }
    let(:smurfy_message_sample){ Icss::Meta::MessageSample.receive(samp_msg_hsh) }

    let(:message_with_sample){ Icss::Meta::Message.receive( smurfy_message_hsh.merge(:samples => [samp_msg_hsh])) }
    it 'is created by its message' do
      message_with_sample.should be_a(Icss::Meta::Message)
      message_with_sample.samples.map(&:class).should == [Icss::Meta::MessageSample]
    end
    it 'knows its message' do
      message_with_sample.samples.first.message.should == message_with_sample
    end

    describe 'basic behavior' do
      subject{ smurfy_message_sample }
      its('name'){         should == 'lambada' }
      its('request'){      should == [{ :smurfiness => 1, :blondness => 12 }] }
      its('response_hsh'){ should == { :smurfiness => 1, :tool => :pipesmurf, :weapon => :broadsmurf } }
    end

    # context 'loading from API'  do
    #   it 'constructs a URL'
    #   it 'loads'
    #   it 'accepts a server'
    # end

  end

  # ===========================================================================
  #
  # Message
  #

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

  let(:fun_protocol_hsh){
    { :protocol => 'smurf.village.fun',
      :messages => { :dance => smurfy_message_hsh } } }
  let(:fun_protocol){ Icss::Meta::Protocol.receive(fun_protocol_hsh) }
    #
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
        :request  => [{:name => :params, :type => "poppa"}],
        :response => "smurfette",
        :doc      => "this is how we dance",
        :errors   => ["oops"],
        :samples  => []
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
        msg.request.map{|r| r.is_reference? }.should == [false]
      end
    end

  end

end
