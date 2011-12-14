require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'icss'

describe Icss::Meta::Protocol do
  
  let(:simple_icss) do
    Icss::Meta::Protocol.receive_from_file(ENV.root_path('examples/chronic.icss.yaml'))
  end

  it 'loads cleanly' do
    simple_icss.basename.should == 'chronic'
    simple_icss.fullname.should == 'st.time_utils.chronic'
  end

  describe '#fullname' do
    it 'has namespace and basename' do
      simple_icss.fullname.should == 'st.time_utils.chronic'
      simple_icss.namespace = nil
      simple_icss.fullname.should == 'chronic'
    end
  end
  describe '#path' do
    it 'is a / separated version of the name, with no / at start' do
      simple_icss.path.should == 'st/time_utils/chronic'
    end
  end
  describe '#doc' do
    it 'takes a doc string' do
      simple_icss.doc.should == 'A series of calls hooking into the Chronic ruby gem'
    end
  end

  describe 'types' do
    it 'has an array of types' do
      simple_icss.types.map(&:basename).should == ['chronic_parse_params', 'chronic_parse_response']
    end
  end

  describe 'messages' do
    it 'has a hash of messages' do
      simple_icss.messages.keys.should == ['parse']
    end

    it 'named each message for its key' do
      simple_icss.messages['parse'].basename.should == 'parse'
      simple_icss.receive!({ :messages => { 'foo' => { :request => [] } }})
      simple_icss.messages['foo'].basename.should == 'foo'
    end

    it '#find_message' do
      msg = simple_icss.find_message(:parse)
      msg.should be_a(Icss::Meta::Message) ; msg.basename.should == 'parse'
      msg = simple_icss.find_message('st.time_utils.parse')
      msg.should be_a(Icss::Meta::Message) ; msg.basename.should == 'parse'
      msg = simple_icss.find_message('st/time_utils/parse')
      msg.should be_a(Icss::Meta::Message) ; msg.basename.should == 'parse'
    end
  end

  describe 'targets' do
    it 'has a hash of targets' do
      simple_icss.targets.keys.should == [:catalog]
      simple_icss.targets[:catalog].first.should be_a(Icss::CatalogTarget)
      simple_icss.targets[:catalog].first.basename.should == 'st_time_utils_chronic_parse'
    end
  end
  
  describe 'license' do
    it 'returns nil if no license_id specified' do
      simple_icss.license.should be_nil
    end
    it 'raises Icss::NotFoundError if license_id specified and not found' do
      simple_icss.license_id = 'not_found_license'
      lambda{ simple_icss.license }.should raise_error(Icss::NotFoundError, /Cannot find .*/)
    end
    it 'returns the Icss::Meta::License object' do
      license = Icss::Meta::License.receive_from_file(ENV.root_path('examples/license.icss.yaml'))
      simple_icss.license_id = 'licenses.example'
      simple_icss.license.should == license
    end
  end
  
  
  
  describe 'sources' do
    it 'returns empty array if no source_ids specified' do
      simple_icss.sources.should == {}
    end
    it 'raises Icss::NotFoundError if license_id specified and not found' do
      simple_icss.credits = { :role => 'not_found_license' }
      lambda{ simple_icss.sources }.should raise_error(Icss::NotFoundError, /Cannot find .*/)
    end
    it 'returns array of Icss::Meta::Source objects' do
      source2 = Icss::Meta::Source.receive_from_file(ENV.root_path('examples/source2.icss.yaml'))
      source1 = Icss::Meta::Source.receive_from_file(ENV.root_path('examples/source1.icss.yaml'))
      simple_icss.credits = {:main => 'sources.source1', :uploaded => 'sources.source2'}
      simple_icss.sources.should == { :main => source1, :uploaded => source2 }
    end
  end

  describe 'validations' do
    it 'validates protocol name' do
      simple_icss.should be_valid
      simple_icss.protocol = '' ;    simple_icss.should_not be_valid ; simple_icss.errors[:protocol].should include("can't be blank")
      simple_icss.protocol = '1bz' ; simple_icss.should_not be_valid ; simple_icss.errors[:protocol].should include("must start with [A-Za-z_] and contain only [A-Za-z0-9_].")
    end

    it 'validates namespace' do
      simple_icss.should be_valid
      simple_icss.namespace = '' ;    simple_icss.should_not be_valid ; simple_icss.errors[:namespace].should include("can't be blank")
      simple_icss.namespace = '1bz' ; simple_icss.should_not be_valid ; simple_icss.errors[:namespace].first.should =~ /Segments that start with.*joined by.*dots/
    end
  end

  describe '#to_hash' do
    it 'roundtrips' do
      simple_icss.license_id = 'licenses.example'
      simple_icss.credits    = { :original => 'sources.source1' }
      simple_icss.tags       = ['tag1', 'tag2', 'tag3']
      simple_icss.categories = ['category1', 'category2', 'category3']
      hsh = simple_icss.to_hash
      hsh.should == {
        :namespace=>"st.time_utils", :protocol=>"chronic",
        :doc=>"A series of calls hooking into the Chronic ruby gem",
        :title => "Utils - Parse Times",
        :license_id=>"licenses.example",
        :credits=>{:original=>"sources.source1"},
        :tags=>['tag1', 'tag2', 'tag3'],
        :categories=>['category1', 'category2', 'category3'],
        :types => [
          {:name=>"st.time_utils.chronic_parse_params",
           :namespace=>"st.time_utils",
           :type=>:record,
           :doc=>"Query API parameters for the /st/time_utils/chronic/parse call",
            :fields=>[
              {:name=>:time_str,             :type=>:string, :doc=>"The string to parse."},
              {:name=>:context,              :type=>:symbol, :doc=>"<tt>past</tt> or <tt>future</tt> (defaults to <tt>future</tt>)\nIf your string represents a birthday, you can set <tt>context</tt> to <tt>past</tt> and if an ambiguous string is given, it will assume it is in the past. Specify <tt>future</tt> or omit to set a future context."},
              {:name=>:now,                  :type=>:time,   :doc=>"Time (defaults to Time.now)\nBy setting <tt>:now</tt> to a Time, all computations will be based off of that time instead of Time.now. If set to nil, Chronic will use the current time in UTC. You must supply a date that unambiguously parses with the much-less-generous ruby Time.parse()"},
              {:name=>:ambiguous_time_range, :type=>:int,    :doc=>"Integer or <tt>:none</tt> (defaults to <tt>6</tt> (6am-6pm))\nIf an Integer is given, ambiguous times (like 5:00) will be assumed to be within the range of that time in the AM to that time in the PM. For example, if you set it to <tt>7</tt>, then the parser will look for the time between 7am and 7pm. In the case of 5:00, it would assume that means 5:00pm. If <tt>:none</tt> is given, no assumption will be made, and the first matching instance of that time will be used."}
            ]},
          {:name=>"st.time_utils.chronic_parse_response",
           :namespace=>"st.time_utils",
           :type=>:record,
           :doc=>"Query API response for the /util/time/chronic/parse call",
            :fields=>[
              {:name=>:time,                 :type=>:string, :doc=>"The UTC parsed time, as a \"ISO 8601 combined date time\":http://en.wikipedia.org/wiki/ISO_8601 string."},
              {:name=>:epoch_seconds,        :type=>:int,    :doc=>"The UTC parsed time, as \"epoch seconds\":http://en.wikipedia.org/wiki/Epoch_seconds integer."}
            ]}
        ],
        :messages => {
          :parse => {
            :request  =>[{:name=>:chronic_parse_params, :type=>"st.time_utils.chronic_parse_params"}],
            :response =>"st.time_utils.chronic_parse_response",
            :doc=>"\nChronic is a natural language date/time parser written in pure Ruby. See below\nfor the wide variety of formats Chronic will parse.",
            :samples  =>[{
                :request=>[{"time_str"=>"one hour ago", "now"=>"2007-03-16T12:09:08Z"}],
                :response=>{"epoch_seconds"=>1174043348, "time"=>"2007-03-16T11:09:08Z"}, :url=>"?now=2007-03-16T12%3A09%3A08Z&time_str=one%20hour%20ago"},
              {:request=>[{"time_str"=>"Yesterday", "now"=>"5:06:07T2010-08-08Z"}],
                :response=>{"epoch_seconds"=>1281182400, "time"=>"2010-08-07T12:00:00Z"}, :url=>"?now=5%3A06%3A07%202010-08-08&time_str=Yesterday"},
              {:url=>"?time_str=5pm+on+November+4th&context=past"}]
          },
        },
        :data_assets=>[],
        :code_assets=>[{:location=>"code/chronic_endpoint.rb"}],
        :targets => {:catalog=>[{:name=>"st_time_utils_chronic_parse", :title=>"Utils - Parse Times", :description=>"An API call to parse human-readable date / time strings", :tags=>["apiawesome", "ruby", "gems", "chronic", "time", "date", "util", "parse"], :messages=>["parse"]}]},
      }
    end
  end

end

