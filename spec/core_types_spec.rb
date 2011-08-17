require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'yaml'
require 'icss'

module Icss
  class Numeric              < Numeric              ; end

  class Thing
  end

  module Business
    class Organization       < Thing                ; end
  end

  module Social
    class Person             < Thing                ; end
    class ContactPoint                              ; end
  end

  module Geo
    class Place              < Thing                ; end
    class AdministrativeArea < Place                ; end
    class Country            < AdministrativeArea   ; end
    class PostalAddress      < Social::ContactPoint ; end
    class GeoCoordinates                            ; end
  end

  module Culture
    class CreativeWork       < Thing                ; end
    class MediaObject        < CreativeWork         ; end
    class AudioObject        < MediaObject          ; end
    class VideoObject        < MediaObject          ; end
    class Review             < CreativeWork         ; end
    class Photograph         < CreativeWork         ; end
    class MusicRecording     < CreativeWork         ; end
    class MusicPlaylist      < CreativeWork         ; end
    class MusicAlbum         < MusicPlaylist        ; end
  end

  module Ev
    class Event              < Thing                ; end
  end

  module Mu
    class Quantity           < Numeric              ; end
    class Rating                                    ; end
    class AggregateQuantity                         ; end
  end

  module Prod
    class Product            < Thing                ; end
    class ItemAvailability                          ; end
    class OfferItemCondition                        ; end
    class Offer                                     ; end
    class AggregateRating    < Icss::Mu::Rating     ; end
  end
end


def core_files
  %w[
    thing
prod.aggregate_rating prod.offer
social.contact_point
geo.geo_coordinates
geo.postal_address
geo.place
ev/event
geo.country
culture.creative_work
culture.media_object culture.audio_object culture.photograph
culture.article

  ]   #.map{|filename| Dir[ ENV.root_path('examples/infochimps_catalog/core', filename.gsub(/\./, '/')+".icss.yaml") ] }.flatten
end

def example_files(filename)
  Dir[ENV.root_path('examples/infochimps_catalog', filename+".icss.yaml")]
end

example_files('core/*/*').each do |filename|
  describe filename do
    it "loads #{filename}" do

      filename = filename.gsub(%r{.*core/([^\.]+)\.icss\.yaml$}, '\1')
      Icss::Meta::Type.load_type(filename)

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
#   it 'warns if you say :of => FooFactory (should probably be :with if it is a Factory)'
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
