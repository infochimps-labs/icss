#!/usr/bin/env ruby

require 'rubygems'
require 'rspec'

def test_hash
  {
    'namespace'   => 'foo.bar',
    'protocol'    => 'baz',
    'targets'     => [
      {
        'catalog' => {
          'title' => "Foo Bar Baz Dataset",
          'desc'  => "The best dataset ins the world!",
          'tags'  => %w[ foo bar baz ]
        }
      },
      {
        'hbase'   => {
          'table' => 'foo_bar_table'
        }
      }
    ],
    'types'       => [
      {
        'name'    => 'baz_record',
        'doc'     => 'A baz data record.',
        'type'    => 'record',
        'fields'  => []
      }
    ]
  }
end

class Hash
  def super_merge! icss

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

  it "should allow a change to a top level key => value" do
    overlay = { 'protocol' => 'TEST' }
    @icss.super_merge!(overlay).should == {
      'namespace'   => 'foo.bar',
      'protocol'    => 'TEST',
      'targets'     => [
        {
          'catalog' => {
            'title' => "Foo Bar Baz Dataset",
            'desc'  => "The best dataset ins the world!",
            'tags'  => %w[ foo bar baz ]
          }
        },
        {
          'hbase'   => {
            'table' => 'foo_bar_table'
          }
        }
      ],
      'types'       => [
        {
          'name'    => 'baz_record',
          'doc'     => 'A baz data record.',
          'type'    => 'record',
          'fields'  => []
        }
      ]
    }
  end

  it "should allow an addition to the targets hash" do
    overlay = { 'targets' => [ { 'TEST' => 'TEST'} ] }
    @icss.super_merge!(overlay).should == {
      'namespace'   => 'foo.bar',
      'protocol'    => 'baz',
      'targets'     => [
        { 'TEST' => 'TEST' },
        {
          'catalog' => {
            'title' => "Foo Bar Baz Dataset",
            'desc'  => "The best dataset ins the world!",
            'tags'  => %w[ foo bar baz ]
          }
        },
        {
          'hbase'   => {
            'table' => 'foo_bar_table'
          }
        }
      ],
      'types'       => [
        {
          'name'    => 'baz_record',
          'doc'     => 'A baz data record.',
          'type'    => 'record',
          'fields'  => []
        }
      ]
    }
  end

end


