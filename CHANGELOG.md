
## v0.2.0 mid-Aug 2011

Major rethunk.

* Type behavior is provided by 
* 

TODO:

* move Targets into troop (?)


#### CatalogTarget becomes small

Become protocol attributes:
* `name`        -- protocol `name` (ie. the `protocol` field)
* `license`     -- protocol `license`
* `title`       -- alias for protocol's name
* `description` -- protocol `doc`
* `tags`        -- protocol `keywords` 

These stay:
* `owner`, `price`, `messages`, `packages`

These move from protocol to CatalogTarget:
* update_frequency
* namespace

## v0.1.0 June 7 2011

* New receiver from gorillib

## v0.0.3 May 22 2011

* used gorillib, got rid of active_support, extlib HOORAY
* moved Receiver to gorillib.
* *breaking change*. Gorillib changed the signature of receive() to be @receive(*constructor_args, hsh)@ (formerly, the hsh was first).
