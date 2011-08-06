require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'icss'

module Icss
  class Entity
  end
  class Thing < Icss::Entity
    include Icss::Type::RecordType
    field :name,        String, :doc => 'The name of the item.'
    field :description, String,   :doc => 'A short description of the item.'
    field :image,       String,    :doc => 'URL of an image of the item.'
    field :url,         String,    :doc => 'URL of the item.'
  end
  module Core
    class Place < Icss::Thing
      # extend Icss::Type::RecordType
      field :address_locality, String
      field :address_region,   String
    end
    # http://schema.org/Event
    class Event < Icss::Thing
      field :start_date,  Time,   :doc => 'The start date and time of the event (in [ISO 8601 date format](http://en.wikipedia.org/wiki/ISO_8601)).'
      field :attendees,   Array,  :of => Object # Icss::Core::Person
      field :location,    Icss::Core::Place
      field :duration,    Object, :doc => 'The duration of the item (movie, audio recording, event, etc.) in [ISO 8601 date format](http://en.wikipedia.org/wiki/ISO_8601)).'
    end
  end
  module Astronomy
    class UfoSighting < Icss::Core::Event
      field :ufo_craft_shape, String
    end
  end
end

describe 'instances' do
  it '#new_record?'
  context 'partial response'
  context 'formatting'
  context 'reshaping' do
    it '#to_model'
    it '#to_param'
    it '#to_key' # Returns an Enumerable of all key attributes if any is set, regardless if the object is persisted or not
  end

end

describe 'fields' do
  context '#name'     do ; end
  context '#doc'      do ; end
  context '#type'     do ; end
  context '#default'  do ; end
  context '#index'
  context '#versionating' do
    # acro versioning
  end
  context '#order' do
    it 'has sort_order'
    it 'order is an alias for sort_order'
    it 'is "ascending" by default'
    it 'sort_order_direction gives -1 / 0 / 1 for descending / ignore / ascending (default)'
  end
  context 'sugar' do
    it '#record?'
    it '#union?'
    it '#enum?'
  end
  it 'properties can find themselves in registry'
  it 'warns if you say "description" (should be "doc")'
  it 'warns if you say :of => FooFactory (should probably be :with if it is a Factory)'

  context '' do
    # universe, dimension, representation,
    # measurement_count, maximum_value, minimum_value, total_value, median_value, average_value, stdev_value
  end
end


describe 'hooks' do
  describe 'after_receive'
  # before/after initialize, validation, save, create, commit, rollback, destroy
  # #dirty?, #new_record?
end

# # not yet
# describe 'associations' do
#   it '.belongs_to'
#   it '.has_one'
#   it '.has_many_through'
#   it '.has_many'
# ASSOCIATION_METHODS  = [:includes, :eager_load, :preload]
# MULTI_VALUE_METHODS  = [:select, :group, :order, :joins, :where, :having]
# SINGLE_VALUE_METHODS = [:limit, :offset, :lock, :readonly, :create_with, :from]
# end


describe 'aspects' do
end

describe 'relationships' do
end

# describe Icss::Entity do
#
# end

