require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'icss'
require 'icss/type/new_factory'

class Text < String ; end
class Url  < String ; end
class Duration
  def initialize(t1_t2)
    receive_times(t1_t2)
  end

  def receive_times(t1_t2)
    self.t1, self.t2 = t1_t2
  end

  def receive!(t1_t2)
    receive_times(t1_t2)
    super({})
  end
end

module Icss
  class Entity
  end
  class Thing < Icss::Entity
    field :name,        String, :doc => 'The name of the item.'
    field :description, Text,   :doc => 'A short description of the item.'
    field :image,       Url,    :doc => 'URL of an image of the item.'
    field :url,         Url,    :doc => 'URL of the item.'
  end
  module Core
    class Place < Icss::Thing
      # extend Icss::Meta::RecordType
      field :address_locality, String
      field :address_region,   String
    end
    # http://schema.org/Event
    class Event < Icss::Thing
      field :start_date,  Time,   :doc => 'The start date and time of the event (in [ISO 8601 date format](http://en.wikipedia.org/wiki/ISO_8601)).'
      field :attendees,   Array,  :of => Object # Icss::Core::Person
      field :location,    Icss::Core::Place
      field :duration,    Duration, :doc => 'The duration of the item (movie, audio recording, event, etc.) in [ISO 8601 date format](http://en.wikipedia.org/wiki/ISO_8601)).'
    end
  end
  module Astronomy
    class UfoSighting < Icss::Core::Event
      field :ufo_craft_shape, String
    end
  end
end


describe 'Icss::Something::Doohickey' do

  it 'Icss::Something::Doohickey describes behavior of a "doohickey"; Icss::Something::Doohickey instances embody individual doohickeys; Icss::Meta::Something::DoohickeyType mediates the type description'


  context 'is a "type"' do

    it "with namespace, name, fullname, and doc" do
      [:namespace, :name, :fullname, :doc ]
    end

  end

  context 'is_a (inheritance)' do
    it 'knows its direct Icss superclass'
    it 'knows its Icss mixin classes'
  end

  context 'synthesizing' do
    it 'has a Meta model to '
  end

  context 'has properties' do
    it 'described by its #fields'

    context 'container types' do

      it 'field foo, Array, :of   => FooClass validates instances are is_a?(FooClass)'
      it 'field foo, Array, :with => FooFactory validates instances are is_a?(FooFactory.product_klass)'

      it ''

    end
  end

  context 'special properties' do
    it '_domain_id_field'
    it '_primary_location_field'
    it '_slug' # ??
  end

  context 'name' do
    context ':i18n_key'
    context ':human_name => '
    context ':singular_name => '
    context ':plural_name => '
    context ':uncountable => '
  end

  context 'generates instances' do
  end

  context '.field' do
    context 'decorates the Meta module of the class' do
      it 'with accessors'
      it 'with the appropriate receive_foo method'
      it 'with new entry in .fields'
    end

    it "sets the field's name"

    context 'type' do
      it 'class uses that class'
      it 'string looks up the class'
      it ':remaining instruments rcvr_remaining'

    end

    context ':default =>' do
      it 'try_dups the object on receipt'
      it 'try_dups the object when setting default'
      it 'creates an after_receive hook to set the default'
    end

    context ':required =>' do
      it 'adds a validator'
    end

    context ':validates' do
      context 'length' do
        # { :is => :==, :minimum => :>=, :maximum => :<= }.freeze
      end

      it 'exclusion (on container type)'
      it 'format'
      it 'numericality' do
        # { :greater_than => :>, :greater_than_or_equal_to => :>=, :equal_to => :==, :less_than => :<, :less_than_or_equal_to => :<=, :odd => :odd?, :even => :even? }.freeze
      end
      it 'presence'
      it 'uniqueness'
    end

    context ':index => ' do
      it 'primary key'
      it 'foreign key'
      it 'uniqueness constraint'
    end

    context ':sort_order =>' do
    end

    context ':access => ' do
      it '[default or nil] -- attr_accessor'
      it ':read_only       -- attr_reader'
      it ':write_only      -- attr_writer'
      it ':none            -- no accessor'   # none? virtual? private? protected?
    end

    context ':after_receive'

    context ':i18n_key'
    context ':human_name => '
    context ':singular_name => '
    context ':plural_name => '
    context ':uncountable => '

    context :serialization
    it '#serializable_hash'

    # constant
    # mass assignment security: accessible,

    it 'works on the parent Meta module type, not '

  end
end

described 'instances' do
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

