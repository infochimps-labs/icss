#!/usr/bin/env ruby

require 'rubygems'
require 'rspec'

def test_hash
  {
    'test1' => 'foo',
    'test2' => { :a => 'foo' },
    'test3' => ['foo', 'bar'],
    'test4' => { :a => { :b => 'foo'} },
    'test5' => { :a => ['foo', 'bar'] },
    'test6' => { :a => { :b => 'foo', :c => 'bar' } },
    'test7' => { :a => [ { :b => 'foo' }, { :c => 'bar' } ] }
  }
end

class Hash
  def super_merge! obj
    case obj
    when Hash then self.merge(obj)
    when Array then self.merge(obj)
    end
  end
end

class Array
  def overlay obj
  end
end

describe "The #super_merge! method" do
  before :each do
    @icss = test_hash
  end

  it "should add a new key when no matching key is found" do
    overlay = { 'test0' => 'foo' }
    @icss.super_merge!(overlay).should == {
      'test0' => 'foo',
      'test1' => 'foo',
      'test2' => { :a => 'foo' },
      'test3' => ['foo', 'bar'],
      'test4' => { :a => { :b => 'foo'} },
      'test5' => { :a => ['foo', 'bar'] },
      'test6' => { :a => { :b => 'foo', :c => 'bar' } },
      'test7' => { :a => [ { :b => 'foo' }, { :c => 'bar' } ] }
    }
  end

  it "should update the string value of a key when a match is found" do
    overlay = { 'test1' => 'bar' }
    @icss.super_merge!(overlay).should == {
      'test1' => 'bar',
      'test2' => { :a => 'foo' },
      'test3' => ['foo', 'bar'],
      'test4' => { :a => { :b => 'foo'} },
      'test5' => { :a => ['foo', 'bar'] },
      'test6' => { :a => { :b => 'foo', :c => 'bar' } },
      'test7' => { :a => [ { :b => 'foo' }, { :c => 'bar' } ] }
    }
  end

  it "should update the hash value of a key when a match is found" do
    overlay = { 'test2' => { :b => 'bar' } }
    @icss.super_merge!(overlay).should == {
      'test1' => 'foo',
      'test2' => { :b => 'bar' },
      'test3' => ['foo', 'bar'],
      'test4' => { :a => { :b => 'foo'} },
      'test5' => { :a => ['foo', 'bar'] },
      'test6' => { :a => { :b => 'foo', :c => 'bar' } },
      'test7' => { :a => [ { :b => 'foo' }, { :c => 'bar' } ] }
    }
  end

  it "should update the internal string value of a key when a match is found internally" do
    overlay = { 'test2' => { :a => 'bar' } }
    @icss.super_merge!(overlay).should == {
      'test1' => 'foo',
      'test2' => { :a => 'bar' },
      'test3' => ['foo', 'bar'],
      'test4' => { :a => { :b => 'foo'} },
      'test5' => { :a => ['foo', 'bar'] },
      'test6' => { :a => { :b => 'foo', :c => 'bar' } },
      'test7' => { :a => [ { :b => 'foo' }, { :c => 'bar' } ] }
  }
  end

  it "should update the array value of a key when a match is found" do
    overlay = { 'test3' => ['baz', 'qux'] }
    @icss.super_merge!(overlay).should == {
      'test1' => 'foo',
      'test2' => { :a => 'foo' },
      'test3' => ['baz', 'qux'],
      'test4' => { :a => { :b => 'foo'} },
      'test5' => { :a => ['foo', 'bar'] },
      'test6' => { :a => { :b => 'foo', :c => 'bar' } },
      'test7' => { :a => [ { :b => 'foo' }, { :c => 'bar' } ] }
    }
  end

  it "should update the internal hash value of a key when a match is found internally" do
    overlay = { 'test4' => { :a => { :c => 'foo' } } }
    @icss.super_merge!(overlay).should == {
      'test1' => 'foo',
      'test2' => { :a => 'foo' },
      'test3' => ['foo', 'bar'],
      'test4' => { :a => { :c => 'foo' } },
      'test5' => { :a => ['foo', 'bar'] },
      'test6' => { :a => { :b => 'foo', :c => 'bar' } },
      'test7' => { :a => [ { :b => 'foo' }, { :c => 'bar' } ] }
    }
  end
end


