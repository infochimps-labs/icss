Icss::Meta::Protocol.load_from_catalog('core/*')
Icss::Meta::Protocol.load_from_catalog('core/geo/place')

if defined?(Icss::Thing)
  Icss::Thing.class_eval do
    include Icss::ReceiverModel
  end
else
  warn "Could not load core type 'thing'. Make sure the catalog (#{Settings.catalog_root}) is where you expect it to be."
end
