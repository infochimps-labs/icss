
# module Icss
#   class Numeric              < Numeric              ; end
#
#   class Thing
#   end
#
#   module Business
#     class Organization       < Thing                ; end
#   end
#
#   module Social
#     class Person             < Thing                ; end
#     class ContactPoint                              ; end
#   end
#
#   module Geo
#     class Place              < Thing                ; end
#     class AdministrativeArea < Place                ; end
#     class Country            < AdministrativeArea   ; end
#     class PostalAddress      < Social::ContactPoint ; end
#     class GeoCoordinates                            ; end
#   end
#
#   module Culture
#     class CreativeWork       < Thing                ; end
#     class MediaObject        < CreativeWork         ; end
#     class AudioObject        < MediaObject          ; end
#     class VideoObject        < MediaObject          ; end
#     class Review             < CreativeWork         ; end
#     class Photograph         < CreativeWork         ; end
#     class MusicRecording     < CreativeWork         ; end
#     class MusicPlaylist      < CreativeWork         ; end
#     class MusicAlbum         < MusicPlaylist        ; end
#   end
#
#   module Ev
#     class Event              < Thing                ; end
#   end
#
#   module Mu
#     class Quantity           < Numeric              ; end
#     class Rating                                    ; end
#     class AggregateQuantity                         ; end
#   end
#
#   module Prod
#     class Product            < Thing                ; end
#     # class ItemAvailability                          ; end
#     # class OfferItemCondition                        ; end
#     class Offer                                     ; end
#     class AggregateRating    < Icss::Mu::Rating     ; end
#   end
# end
