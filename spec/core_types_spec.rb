require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'yaml'
require 'icss'
require 'icss/protocol'
require 'icss/message'

def example_files(filename)
  Dir[ENV.root_path('examples/infochimps_catalog', filename+".icss.yaml")]
end


module Icss
  class Numeric              < Numeric              ; end
end

def core_files
  %w[
   business.educational_organization
  mu/*
  st/*
  business/*
  culture/*
  ev/*
  geo/*
  social/*
  prod/*
  */*

  ]   #.map{|filename| Dir[ ENV.root_path('examples/infochimps_catalog/core', filename.gsub(/\./, '/')+".icss.yaml") ] }.flatten
end

    # thing
    # numeric
    # mu.quantity mu.rating
    # prod.offer
    #
    #
    # culture.creative_work
    # culture.media_object
    #
    # ev.event
    #
    # social.contact_point geo.geo_coordinates geo.postal_address
    # geo.place geo.country

 # culture.photograph mu.aggregate_quantity prod.aggregate_rating
 #    culture.audio_object

# example_files('core/*/*')
count = 0
core_files.each do |filename_patt|
  describe filename_patt do
    it "loads #{filename_patt}" do
      example_files("core/#{filename_patt.gsub(/\./, "/")}").each do |filename|
        filename = filename.gsub(%r{.*core/([^\.]+)\.icss\.yaml$}, '\1')
        Icss::Meta::Protocol.load_from_catalog(filename)
        count += 1
      end
      puts "************* loaded #{count} core types **************"
    end
  end
end




#
# describe 'instances' do
#   it '#new_record?'
#   context 'partial response'
#   context 'formatting'
#   context 'reshaping' do
#     it '#to_model'
#     it '#to_param'
#     it '#to_key' # Returns an Container of all key attributes if any is set, regardless if the object is persisted or not
#   end
#
# end
#
# describe 'fields' do
#   context '#name'     do ; end
#   context '#doc'      do ; end
#   context '#type'     do ; end
#   context '#default'  do ; end
#   context '#index'
#   context '#versionating' do
#     # acro versioning
#   end
#   context '#order' do
#     it 'has sort_order'
#     it 'order is an alias for sort_order'
#     it 'is "ascending" by default'
#     it 'sort_order_direction gives -1 / 0 / 1 for descending / ignore / ascending (default)'
#   end
#   context 'sugar' do
#     it '#record?'
#     it '#union?'
#     it '#enum?'
#   end
#   it 'properties can find themselves in registry'
#   it 'warns if you say "description" (should be "doc")'
#   it 'warns if you say :items => FooFactory (should probably be :with if it is a Factory)'
#
#   context '' do
#     # universe, dimension, representation,
#     # measurement_count, maximum_value, minimum_value, total_value, median_value, average_value, stdev_value
#   end
# end
#
#
# describe 'hooks' do
#   describe 'after_receive'
#   # before/after initialize, validation, save, create, commit, rollback, destroy
#   # #dirty?, #new_record?
# end
#
# # # not yet
# # describe 'associations' do
# #   it '.belongs_to'
# #   it '.has_one'
# #   it '.has_many_through'
# #   it '.has_many'
# # ASSOCIATION_METHODS  = [:includes, :eager_load, :preload]
# # MULTI_VALUE_METHODS  = [:select, :group, :order, :joins, :where, :having]
# # SINGLE_VALUE_METHODS = [:limit, :offset, :lock, :readonly, :create_with, :from]
# # end
#
#
# describe 'aspects' do
# end
#
# describe 'relationships' do
# end
#
# # describe Icss::Entity do
# #
# # end
