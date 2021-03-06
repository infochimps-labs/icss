# p [__FILE__, "core types from ", Settings.catalog_root]

module Icss
  module Encyclopedic ; module Wikipedia ; module Dbpedia ; end ; end ; end
  module Web ; module An ; end ; end
  module Web ; module Analytics ; end ; end
  module Engineering ; module Chemical; module Msds ; end ; end ; end
  module Government ; module Public ; module Acs ; end ; end ; end
  module Language ; module Corpora ; module WordFreq ; end ; end ; end
  module Sports ; module Stats ; module Baseball ; end ; module Vargatron ; end ; end ; end
  module Social  ; module Network ; module Tw ; end ; module Qwerly ; end ; end ;  end
  module Soc  ; module Net ; module Tw ; end ; end ;  end
  module Meta ; module Req ; class Geolocator ; end  ; end ; end
  module St ; class Url < String ; end ; end
  module Geo ; module Location ; end ; end
end

unless defined?(Icss::Geo::Place)
  warn "Could not load core type 'place'. Make sure the catalog (#{Settings.catalog_root}) is where you expect it to be."
end
