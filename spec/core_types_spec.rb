require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'yaml'
require 'icss'
require 'icss/protocol'
require 'icss/message'

def core_files
  %w[ core datasets ].map do |section|
    Dir[File.join(Settings[:catalog_root], section, '**/*.icss.yaml')].map do |fn|
      fn.gsub(%r{.*(#{section}/[^\.]+)\.icss\.yaml$}, '\1')
    end
    # So that we can kinda have random load order, but have it be deterministic, sort by the reversed string
  end.flatten.sort # _by(&:reverse)
end

unless defined?(Log)
  if defined?(Rails)
    Log = Rails.logger
  else
    require 'logger'
    Log = Logger.new($stderr)
  end
end

Log.level = 1

describe 'loads all catalog types' do
  start_time = Time.now
  last_time  = Time.now
  [
    %w[ mu.rating prod.aggregate_rating mu.quantity mu.distance mu.duration
        social.contact_point prod.item_availability prod.offer_item_condition
        geo.geo_coordinates
        culture.creative_work ev.event geo.place business.organization web.web_page_element
        core/web/web_page
         ].map{|s| "core/#{s}" },
    'datasets/science.astronomy.ufo_sighting',
    core_files,
  ].flatten.each do |filename_patt|
    it "loads #{filename_patt}" do
      Icss::Meta::Protocol.find(:all, filename_patt)
      Log.debug "************* loaded #{Icss::Meta::Type.registry.size} core types in #{((Time.now-last_time).to_f * 1000).round} **************"
      last_time = Time.now
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
