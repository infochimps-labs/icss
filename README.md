# The Infochimps Stupid Schema (ICSS)

An ICSS file is a *complete*, *expressive* description of a collection of related data and all associated assets. It is based on the [Avro Protocol](http://avro.apache.org/docs/current/index.html) specification, with some necessary extensions

___________________________________________________________________________
<a name="avro" >
## Avro Protocol, Message, RecordType and Field


### Icss::Meta::{Types}

* base meta-type: Icss::Meta::Type
* 





All types respond to:

* new
* receive
* to_schema
* typename
* fullname
* namespace   (blank for
* schema_classifier


and their instances respond to

* receive!


* Schema Classifier

* `:defined_type` (string)
* `:primitive_type`
  - `null`  -- `Icss::Type::NilClass`

* primitive types: Icss::{StringType, 


including X puts X's instance methods in with my instance methods
extending X puts X's instance methods in with my OWN      methods


    class                   meta type                 | class                                 | class                   | obj
    String                  Icss::Meta::PrimitiveType | doc  ns/n/fn  type metatype to_schema |                         |

    < Icss::ArrayType       Icss::Meta::ArraySchema   | doc  ns/n/fn  type metatype to_schema | items                   |
    < Icss::HashType        Icss::Meta::HashSchema    | doc  ns/n/fn  type metatype to_schema | values                  |

    < Icss::EnumType        Icss::Meta::EnumSchema    | doc  ns/n/fn  type metatype to_schema | items                   |
    < Icss::FixedType       Icss::Meta::FixedSchema   | doc  ns/n/fn  type metatype to_schema | items                   |
    < Icss::UnionType       Icss::Meta::              | doc  ns/n/fn  type metatype to_schema | items                   |
    Icss::Entity            Icss::Meta::RecordType    | doc  ns/n/fn  type metatype to_schema | fields field receive    | receive!  [methods from fields]
    
    class Icss::Entity
      include Icss::Meta::ReceiverModel
    end
    
    class Icss::Thing < Icss::Entity
      field :name, String
      field :url,  Url,   :validates => { :format => /[a-z][a-z]/ }
    end
    class Icss::Place < Icss::Thing
      field :geo,  GeoCoordinates
      field :cc,   String, :validates => { :format => /[a-z][a-z]/ }
    end

                          Thing   M::ThingType  Place  M::PlaceType  M::PlaceSchema    M::ReceiverModel  M::ReceiverModel::Schema  M::Type::RecordType
    Place.new           | --      #geo, #cc     --     #name, #url   --                #receive!              
    Place               |                                                                                .field, .fields, .rcvr    .doc/.ns/.n/.fn/.metatype/.to_sch
    M::PlaceType        |                                                              

    M::Type::RecordType  
    - receive 
      - makes klass, meta_klass
      
    Meta::ArrayTypeFactory
    - ArrayOfFooType < ArrayType         if `items` is primitive then `Icss::ArrayOfFooType < Icss::ArrayType` else anon. subclass of `Icss::ArrayType`
    - kl.incl M::ArrayOfFooType          
    - kl.ext  M::ArrayOfFooSchema        `.items` (written in by Meta::ArrayTypeFactory)
    - ArrayType                          `.receive(arr)` (iterates .receive_item() over arr)


New record type:

    instance methods:                               #receive!, #_receive_attr, #run_after_receivers
    class    methods:   .field .fields .field_names .receive .rcvr .rcvr_remaining .after_receive .after_receivers 

    making a Meta::record:
                                        class methods                         inst. methods        
    Widget, includes M::Record:
    - kl.incl M::RecordType                 
    - kl.ext  M::RecordSchema           .field .fields .field_names
    - kl.incl M::Receiver                                                     #receive!
    - kl.ext  M::Receiver::CM           .rcvr .receive .rcvr_remaining, &c            

    field "foo", Integer              
    - kl.incl M::WidgetType                                                   #foo, #foo=, #receive_foo?
    - kl.ext  M::WidgetSchema           modifies field, field_names

    M::Record.receive(:name => 'widget', :type => 'record', :fields => [{ :name => 'foo', :type => 'int' }] )

    Meta::UnionType
    - klass                              instance of `Icss::Meta::UnionType`
    - kl.incl M::Type::ArrayOfFooType          
    - kl.ext  M::Type::ArrayOfFooSchema  `.items`, `.receive(arr)` (iterates .receive_item() over arr)
    
    doc/ns/n/fn/metatype/to_sch fields field | receive  | receive! [methods from fields] |    


when I call field
  - adds accessor     instance methods via my metatype
  - adds rcvr         instance methods via my metatype
  - adds receive      class    methods via my metatype extender
  - adds to_schema &c class    methods via my metatype extender

    
### Namespacing


    avro        kind        ruby           json      example                schema example
    ---------   ---------   ------------   -------   ---------              --------------
    null        primitive   NilClassType   null      nil                    'null'
    boolean     primitive   BooleanType    boolean   true                   'boolean'
    int         primitive   IntegerType    integer   1                      'int'
    long        primitive   LongType       integer   1                      'long'
    float       primitive   FloatType      number    1.1                    'float'
    double      primitive   DoubleType     number    1.1                    'double'
    bytes       primitive   BinaryType     string    "\u00FF"               'bytes'
    string      primitive   StringType     string    "foo"                  'string'

    array       container   ArrayType      array     [1,2]                  { 'type': 'array',  'items': 'int' }
    map         container   HashType       object    { "a": 1 }             { 'type': 'map',    'values': 'int' }

    record      named       (RecordType)   object    {"a": 1}               { 'type': 'record', 'name': 'bob',    'fields':[...] }
    enum        named       (EnumType)     string    "heads"                { 'type': 'enum',   'name': 'result', 'symbols': ['heads', 'tails'] }
    fixed       named       (FixedType)    string    "\xBD\xF3)Q"           { 'type': 'fixed',  'name': 'crc32',  'length': 4 }
    union       named       (UnionType)    object                           [ 'long', { 'type': 'array', 'items': 'int' } ]

    date        simple      DateType       string    "2011-01-02"           'date'
    time        simple      TimeType       string    "2011-01-02T03:04:05Z" 'time'
    text        simple      TextType       string    "long text"            'text'
    regexp      simple      RegexpType     string    "^hel*o newman"        'regexp'
    url         simple      UrlType        string    "http://..."           'url'
    file_path   simple      FilePathType   string    "/tmp/foo"             'file_path'
    epoch_time  simple      EpochTimeType  string    1312507492             'epoch_time'

Notes:
* primitive types are also simple types

__________________________________________________________________________
__________________________________________________________________________
__________________________________________________________________________

Old receiver klass methods:

      :after_receive,      :after_receivers(=?),     :receiver_defaults,
      :receiver_attrs(=?), :receiver_attr_names(=?), :members, 
      :rcvr_accessor,      :rcvr, :rcvr_reader,      :rcvr_writer, :rcvr_remaining, 
      :receiver_body_for,  :type_to_klass,           :consume_tuple,   :tuple_keys,

Old receiver instance methods:
      
      :bob, :bob, :receive_bob, 
      :receive!, :_receive_attr, :receiver_attrs(=?), :receiver_attr_names(=?),  
      :after_receivers(=?) :run_after_receivers, :impose_defaults!, :replace_options!, :attr_set?, :to_tuple, :unset!
      

Old ReceiverModel adds to class:

       :__update_callbacks, :define_callbacks, :__create_keyed_callback, :__define_runner, 
       :_parse_validates_options, :_validate_callbacks, :reset_callbacks, :set_callback, :skip_callback,
       :validate, :validate_on_XXX, :validates, :validates_XXX_of, :validates_with, :validators, :validators_on :_validators, :_validators, :_validators?, 
       :model_name, :human_attribute_name, :human_name, :attribute_method?, :i18n_scope, 
       :inherited, :lookup_ancestors, :descendants, :direct_descendants, 
       :keys, :receive_from_file, :receive_json, :receive_yaml, 

and to instance

       :callback, :_validate_callbacks, :_validators, :_validators, :_validators?, :run_callbacks, :run_validations!, 
       :read_attribute_for_validation, :validates_XX_of, :validates_with, :validation_context(=)
       :errors, :to_model, :valid?, :invalid?, :destroyed?, :new_record?,
       :members, :values_of, :convert_key, :merge_from_file!
       (... plus all methods from Enumerable)

__________________________________________________________________________
__________________________________________________________________________
__________________________________________________________________________

___________________________________________________________________________
<a name="core" >
## Icss::Core -- a library of standard types

**Base Types**:

* Primitive types: `Boolean`, `Time` (Date), `Numeric` (Number), `Float`, `Integer`, `String`
* Simple types: `Text`, `Url`

* `Icss::RecordType`
* `Icss::RecordField`
* `Icss::Protocol`
* `Icss::Message`

* `Icss::Thing      < Icss::Entity`
* `Icss::Intangible < Icss::Entity`

**Icss::Thing** (schema.org types):

* `Icss::Core::AggregateRating`
* `Icss::Core::CreativeWork`
* `Icss::Core::GeoCoordinates`
* `Icss::Core::Organization`
* `Icss::Core::Place`
* `Icss::Core::Product`
* `Icss::Core::Review`
* `Icss::Core::ContactPoint`
* `Icss::Core::Event`
* `Icss::Core::MediaObject`
* `Icss::Core::Person`
* `Icss::Core::PostalAddress`
* `Icss::Core::Thing`
* `Icss::Core::Rating`

**Icss::Thing** (added by icss):

* `Icss::Core::Region`
* `Icss::Core::AggregateQuantity`

**Icss::Intangible**:

* Enumeration
  - BookFormatType
  - ItemAvailability
  - OfferItemCondition
* Language
* Offer: aggregateRating, reviews, price, priceCurrency, priceValidUntil, seller, itemCondition, availability, itemOffered
  - AggregateOffer: lowPrice, highPrice, offerCount
* Quantity
  - Distance
  - Duration
  - Energy
  - Mass
* Rating: bestRating, worstRating, ratingValue
  - AggregateRating: itemReviewed, ratingCount, reviewCount
* StructuredValue
  - ContactPoint
    - properties: email, telephone, faxNumber, contactType
  - PostalAddress
    - properties: streetAddress, addressLocality, addressRegion, postalCode, postOfficeBoxNumber, addressCountry
  - GeoCoordinates
    - properties:  latitude, longitude, elevation
  - NutritionInformation
    - properties: servingSize, calories, fatContent, saturatedFatContent, unsaturatedFatContent, transFatContent, carbohydrateContent, sugarContent, fiberContent, proteinContent, cholesterolContent, sodiumContent
* AggregateQuantity
  - WeatherObservation
  - CensusSurvey
  - TimeZone
* Relation                 # The type to be used inside the relations property for icss.core.thing
  * FollowsOnTwitter
  * FriendsOnFaceBook
  * ContainedWithin
  * Hyperlink
  * ...

### Extra properties of Icss::Thing

#### Relations:

    relations: [
      { rel: ["external_link", "reference"] # type of relationship
        weight (strength): xx               # weight of link
        object: { ... thing ...}            # target object
      }, ...
    ]

#### extended_properties

A hash of key-value pairs for remaining properties that cannot pragmatically be schematized:

    extended_properties: [ {property:"",value:""} ]

#### extended_identifiers

Use this to list foreign keys that are worth keeping, but are either not prominent enough or not frequently represented enough to warrant their own property: for example, `musicbrainz_id` or `geonames_id` on a `WikipediaArticle`.

### Design principles drawn from Schema.org

* property names are globally unique and single-tree
  - properties with the same name are always isomorphic. You *must not* use `temperature` in one type to mean "what to set the oven at" and in another to mean "air temperature at start of game". On the other hand, `Organization` and `Place` both have a
  - where there is a semantic difference, prefix your field name with a prefix consistent with your type: `
`Place` has a field `address`; `PostalAddress` has fields `address_region`, `address_locality`, etc.
  - spell things out: `latitude` not `lat`.
* Life is messy, so buy a reasonably-sized (but not excessive) kitchen sink.
  - yes, it's silly that every `Place`, from `Volcano` to `TaxiStand`, has a `telephone` property. But in practice it's harmless, and the simplified type taxonomy proves highly valuable.
* Look to the web and to the real world.
  - find a domain-specific API and note the data structures, fields and naming scheme they use.
* Pragmatism beats purity
  - Schema.org says almost nothing about validation, and *encourages* you to fit round pegs into square holes. A `ScholarlyArticle` does not have attributes for abstract or academic domain. Instead, use `description` and `genre` -- when considering only `ScholarlyArticle`s, it's a harmless misspelling; when considering the great mass of `Article`s as a whole it lets you see how they relate. It also lets you have simple memorable property names, which is a huge win.
  - It's interesting to note that neither Schema.org or Avro have any way to represent complex types *within* their ontology. Overindulging in that kind of omphaloskepsis leads to a deadweight of conceptually beautiful code.

What we added:

* Top level properties on thing: `_type`, `relations`, `aspects`, `extended_properties` and `extended_identifiers`.
* Many types we'd regard as superfluous ('HealthAndBeautyBusiness') have been consigned to a namespace.
* It lacks many we'd regard as primary, such as `AggregateQuantity` and `Region`.
* Properties are underscore cased: `interactionCount` becomes `interaction_count`

What we don't like:

* Union types. We avoided having union types by (in most cases) mandating one; where necessary we specify a single Factory type.
* Multiple inheritance. Yick.
* Messy cardinality: In several places schema.org says a property is plural but gives it a singular name. We've made the property plural, taking a list of whatevers.

### Additional Guidelines

* No property shall ever be named `id`.
* Properties that form natural or primary keys should end in `_id` whenever possible
  - exceptions are made for notable properties: `postal_code`, `url`, etc.
* Records must nominate one property (its `domain_id_property`) to indicate a unique identifier within its domain
* Inheritance vs. Aggregation:
  * if almost all of the behavior applies -> is_a (inheritance)
  * if only a subset of a collection would exhibit this behavior: -> has_a (property)
  * if a few (enough to be significant, not enough to warrant a new field) -> aspect
* An aspect means the two entities are in an important sense the *same thing*: the "Abraham Lincoln" the `Person` and the `WikipediaArticle`. If that article mentioned Lincoln's place of birth, however, that would be a `relation` not an `aspect`.

### Differences between schema.org and icss.core types

Specifically:

* There is a new parent class with no fields, `entity` (`Icss::Entity`).
* `core.thing` and `core.intangible` are *peers* (`core.intangible` is not `is_a: core.thing`), and both `is_a: entity`.
* `Place`:   `contained_in` is a GeoContainmentHierarchy
* `Article`: rename to `article_sections` -- *array* of Text
* `PostalAddress`:
  - adds `address_house_name`, `address_prenum`, `address_sufnum`, `address_number`, `street_prefix`, `street_basename`, `street_type`, `address_unit`, `address_extended`, `address_subregion`, `address_type`, `address_agent`, `address_mail_class`, `neighborhood_id`, `locality_id`, `subregion_id`, `region_id`, `country_id`, `timezone_id`, `continent_id`, and `hemisphere_id`.
  - the `region_id` *must* be the [ISO 3166-2](http://en.wikipedia.org/wiki/ISO_3166-2) id of the region (level 1 admin) -- so, 'US-TX' not 'TX'.
  - the `country_id` *must* be the [ISO 3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) of the country.
* union type banned: `Event#location`  is a Place (not PostalAddress)
* union type banned: `Event#attendees` is an array of `Person` (not Organization)
* `Organization` is a weird mix of properties and needs to be adjusted.
* `Event`
  - if only one date/time (and it is not clearly the end time), use start_date alone.
  - if you *know*, from the domain, that it's appropriate to fill in the duration given start and end (or end given start and duration, or so on), you *should* do so. You must *not* do so generically.

___________________________________________________________________________
<a name="model" >
## Icss::ReceiverModel -- a pragmatic, flexible framework for generic record types


### NamedArray type

Defining

```ruby
  field :slices, NamedArray, :of => AggregateQuantity, :pivoting_on => :name, :receives => :remaining
```

Lets it equivalently live as

```yaml
- name: foo
  average_value: 3
  slices:
  - name: subcat_1
    average_value: 3
  - name: subcat_2
    average_value: 3
```

or naturally pivot to be

```yaml
foo:
  average_value: 3
   subcat_1:
    average_value: 3
  subcat_2:
    average_value: 3
```

All the rcvr_remaining (unclaimed) properties pivot on their :name field to look like the one or the other at your choice.

___________________________________________________________________________
<a name="protocol" >
## Icss::Protocol specifics

### Assets

Assets may include
* data assets (including their location and schema)
* code for api calls (messages) based on the the described records (including their call signature and schema)
* other referenced schema

See [icss_specification.textile](icss/blob/master/icss_specification.textile) for more.

___________________________________________________________________________
<a name="colophon" >
## Colophon

### Credits

Huge thanks to Doug Cutting and the rest of the Avro maintainers.

### Contributing to icss

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

### Copyright

Copyright (c) 2011 Philip (flip) Kromer for Infochimps. See LICENSE.txt for
further details.

