# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'yaml'
require 'icss/serialization/zaml'

describe ZAML do
  describe '#to_zaml' do
    [nil, :my_sym, true, false, 69, 69.0, /my_regexp/,
      ArgumentError.new('my_exception'),
      'my_str',
      {'simple' => :hash, :items => {2 => /pairs/}},
      ['arr', :items, 4, /things/], Time.now, (3..69),
    ].each do |obj|
      it "serializes a #{obj.class}" do
        # woof. This patches over inconsistencies between YAML::Psych and YAML::Syck
        obj.to_zaml.gsub(/ \n/, "\n").should == obj.to_yaml.gsub(/\.\.\.\n\z/m, '').gsub(/ \n/, "\n")
      end
    end
  end

  BASIC_HASH = {
    :name => "a few",
    :nested => "elements",
    :including => "line\nbreaking\nstrings",
    :and_including => "newline terminated\nline\nbreaking\nstrings\n",
    :so => ":what
            :dyathink, :of, :that
          "
  }

  def complex_hash
    { 'complex' => :hash,
      :items => {2 => /pairs/},
      'Iñtërnâtiônàlizætiøn' => "look out for 'funny quotes'.",
      :and => [BASIC_HASH,  { :name => 'bob' }, [], ],
    }
  end

  def complex_hash_with_comments
    {
      ZAML::Comment.new("first comment") => 1,
      'complex' => :hash,
      :items => {2 => /pairs/},
      'Iñtërnâtiônàlizætiøn' => "look out for 'funny quotes'.",
      :and => [
        ZAML::Comment.new("informative comments"),
        BASIC_HASH,
        ZAML::Comment.new("more informative comments, \nspread across\n multiple lines"),
        {
          :name => 'bob',
          ZAML::Comment.new("comment can be in hash key, \nspread across\n multiple lines;") => :zaml_ignores_their_hash_val
        },
        ZAML.padding(3),
        [ZAML::Comment.new("does the right thing \neven when\nis the only item")],
      ],
    }
  end

  context 'valign' do
    it 'accepts an option, defaults to nil' do
      obj = ZAML.new(:valign => 24)
      obj.valign.should == 24
      obj = ZAML.new()
      obj.valign.should == nil
    end

    it 'aligns things' do
      obj = complex_hash_with_comments
      yaml_str = ZAML.dump(obj, '', :valign => 24 )
      # puts yaml_str
      from_yaml = YAML.load(yaml_str)
      from_yaml.should == complex_hash
    end

    it 'matches sample' do
      expected_yaml_str = File.read(ENV.root_path('spec/fixtures/zaml_complex_hash.yaml'))
      yaml_str = ZAML.dump(complex_hash_with_comments, '', :valign => 24 )
      # puts yaml_str
      yaml_str.should == expected_yaml_str
    end
  end
end
