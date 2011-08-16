# The Infochimps Stupid Schema (ICSS)

An ICSS file is a *complete*, *expressive* description of a collection of related data and all associated assets. It is based on the [Avro Protocol](http://avro.apache.org/docs/current/index.html) specification, with some necessary extensions

___________________________________________________________________________
<a name="avro" >
## Avro Protocol, Message, RecordType and Field


    avro        kind        ruby           json      example                schema example
    ---------   ---------   ------------   -------   ---------              --------------
    null        primitive   NilClass       null      nil                    'null'
    boolean     primitive   Boolean        boolean   true                   'boolean'
    int         primitive   Integer        integer   1                      'int'
    long        primitive   Long           integer   1                      'long'
    float       primitive   Float          number    1.1                    'float'
    double      primitive   Double         number    1.1                    'double'
    bytes       primitive   Binary         string    "\u00FF"               'bytes'
    string      primitive   String         string    "foo"                  'string'
    time        simple      Time           string    "2011-01-02T03:04:05Z" 'time'
    symbol      simple      Symbol         string    :belongs_to            'symbol'

    array       container   (ArrayOfXXX)   array     [1,2]                  { 'type': 'array',  'items': 'int' }
    map         container   (HashOfXXX)    object    { "a": 1 }             { 'type': 'map',    'values': 'int' }

    enum        named       (EnumType)     string    "heads"                { 'type': 'enum',   'name': 'result', 'symbols': ['heads', 'tails'] }
    fixed       named       (FixedType)    string    "\xBD\xF3)Q"           { 'type': 'fixed',  'name': 'crc32',  'length': 4 }

    record      rec/named   (RecordType)   object    {"a": 1}               { 'type': 'record', 'name': 'bob',    'fields':[...] }
    error       rec/named   (ErrorType)    object    {"err":"db on fire"}   { 'type': 'record', 'name': 'database_on_fire, 'fields':[...] }

    union       union       <UnionType>    object                           [ 'long', { 'type': 'array', 'items': 'int' } ]

    regexp      simple      Regexp         string    "^hel*o newman"        'regexp'
    url         simple      Url            string    "http://..."           'url'
    file_path   simple      FilePath       string    "/tmp/foo"             'file_path'
    epoch_time  simple      EpochTime      string    1312507492             'epoch_time'


#### Primitives (int, float, string, ...)

Class `.receive` method is just `new` (where appropriate) with the appropriate conversion. Receiving `nil` returns `nil` without error.

#### Simples (date, symbol, ...)

These (like primitve types) have no internal structure -- but they are *not* present in the Avro spec.

#### Types, Properties and Individuals

There are things in the world that we know as "restaurants" -- for example, in
Austin you can't to better than "Torchy's Tacos". It, like all restaurants, have
some notion of a "name" and a "menu".

* "Restaurant" is a _*type*_: a group sharing common properties.
* "Torchy's Tacos" is an _*individual*_.
* "name" and "menu" are _*properties*_ of a type.
* An individual has _*values*_ for those properties: the restaurant "Torchy's
  Taco's" has a menu which includes the "Dirty Sanchez" (no, really.)

In ruby, we might represent this as follows (greatly simplified):

```ruby
    class Restaurant
      field :name, String
      field :menu, Array, :items => String
      field :geo,  GeoCoordinates
    end
    yum = Restaurant.receive({
      :name => "Torchy's Taco's",
      :menu => ["Dirty Sanchez", "Fried Avocado"] ,
      :geo  => { :longitude => 30.295, :latitude => -97.745 },
      })
    yum.name          # "Torchy's Taco's"
    yum.geo.latitude  # -97.745
```

* The _type_ is implemented with the *class* `Restaurant`.
* Its _properties_ are described as `field`s, each with its own type.
* An _individual_ is represented by an *instance* of that class.

Probably most of this was boring and/or familiar. To clear the rest of the
straightforward stuff out of the way,

* A "Restaurant" is a specialization of a "Place": it has a "geo" property, just
  as "Bowling Alley" and "Mountain" do. We'll represent that as straightforward
  inheritance: `Restaurant` is a subclass of `Place`.
* A "Place" is itself a specialization of "Tangible Things", for which we will
  use the ruby class `Thing`.
* A "Restaurant" is actually also a "Business", itself also a specialization of
  "Thing".  Using a trick you'll hear more about below, we can actually handle
  this easily using module inclusion (`include`).

So this gives us (still simplified, but less so):

```ruby
    class Thing
      field :name, String
    end

    class Place < Thing
      field :geo,  GeoCoordinates
    end

    class Business < Thing
      field :opening_hours, Duration
    end

    class Restaurant < Place
      include Meta::BusinessType
      field :menu, Array, :items => String
    end

    class Mountain < Place
      field :height_of_peak, Integer, :doc => "In meters"
    end

    yum = Restaurant.receive({
      :name => "Torchy's Taco's",
      :menu => ["Dirty Sanchez", "Fried Avocado"] ,
      :geo  => { :longitude => 30.295, :latitude => -97.745 },
      })
    yum.name          # "Torchy's Taco's"
    yum.geo.latitude  # -97.745
```

### RecordModel

Including `Icss::Meta::RecordModel` gives you these superpowers:

* `.field` -- create accessors and receivers for a property
* `.fields` and `.field_names` -- describe the fields. (field names is guaranteed in order.)
* `.receive` -- create an instance given a (nested) hash of values; calls
  in turn `.receive` on each field's type.

The class and instance behavior of `Place` (a direct child class of `Thing`) is
effectively (apart from one important detail) as follows:

    Behavior        Model               Instance Methods        Type                    Class Methods              
    --------------  -----------------   -----------------       ---------------------   ------------------------   
    (superclasses)  Object              ...many...                                      ...many...
    structure type:                                             Meta::BaseType          .metamodel,.to_schema
                    Meta::RecordModel   #receive!               Meta::RecordType        .receive, .field, .fields
    parent models:  Thing               #name,#receive_name,&c
    model klass:    Place               #geo, #receive_geo,&c

Note carefully the following relationships:
    
      torchys = Place.new({...})

      # true:
      torchys.is_a? Thing
      torchys.is_a? Meta::RecordModel 
      torchys.is_a? Object

      # not true:
      torchys.is_a? Meta::RecordType
      
      # true:
      Place     < Thing
      Place     < Meta::RecordModel
      Place.is_a? Meta::RecordType

### metamodel

Here's the important detail promised earlier about inheritance. We actually slip
in a little overlay module, the `metamodel`:

    Behavior        Model               Instance Methods        Type                    Class Methods              
    --------------  -----------------   -----------------       ---------------------   ------------------------   
    (superclasses)  Object              ...many...                                      ...many...
    structure type:                                             Meta::BaseType          .metamodel,.to_schema
                    Meta::RecordModel   #receive!               Meta::RecordType        .receive, .field, .fields
    parent models:  Meta::ThingModel    #name,#receive_name,&c
                    Thing               
    metamodel:      Meta::PlaceModel    #geo, #receive_geo,&c
    model klass:    Place                        <--- call super, override things, go crazy --->

This lets us (a) enable multiple inheritance, and (b) let a class declare a
field but only override *some* of its behavior (i.e. still letting you use
`super`).

We scribble all the instance methods for a place onto the `Meta::PlaceModel`
*module*. When the `Place` class calls `include Meta::PlaceModel`, it acquires
the prescribed behavior, but can override as required.  Furthermore, any other
class can accomplish "Placehood" by *also* `include`ing the `Meta::PlaceModel`
metamodel. 

The infochimps API uses this to good effect, where data sets often introduce
behavior across an entire universe of otherwise distinct types. Objects from
Twitter would generically be represented as `Social::Person` (an account),
`Event::UserTweets` (messages), and subclasses of `Geo::Place` (place checkins).
All have implied geolocations, and could naturally coexist on a map. Other data
sources imply other attributes: not just foursquare and yelp but also news
articles and stock filings.  We can inject Twitter geolocation information
without subclassing everything in sight
(`RestaurantOnTwitterThatIsAlsoABranchOfAPubliclyTradedCompany`) or requiring
the prolix madness of an RDF graph
(`<http://ding.us/not/actually/a/url/torchys_tacos>
<http://some.rand.om/ontology#hasPropertyYouCantRememberSpellingOf>
34^^<http://with.com/value/that/is/twelve/miles/long/even/though/its/a/goddamn/integer>`)

### Model vs Type vs Schema

Now we want a way to programmatically describe and generate types. If we're not
careful, we'll end up going mad discussing how to type up the typical type of
type `Type` properly having property `schema` of type `RecordSchema`, or (even
worse) wind up in the omphaloskeptic realm of Semantic Web Ontologies. Eff that
-- this is called the Infochimps Stupid Schema, precisely to remind you it's
just a data model, we should really just relax.

However, if you must spend some time to understand how a small amount of clever
enables that greater and more productive recklessness, a certain measure of
careful terminology is required.

The regular kind of _type_ we've been discussing is a `Model` -- its individuals
correspond to things in the real world. A `Thing` is a model, and most things
are `Thing`s. `Integer` and `IsFriendOf` (a kind of `Relation`) are both models
but not `Thing`s. Recapping what you know,

  - **instances** of a model represent individuals;
  - **instance methods** of a model characterize a type's behavior, specifically
  - **fields**, which represent properties and accept values describing the individual.

We also want to be able to discuss properties and impart shared behavior among
types themselves. For example,

  - a `Restaurant` place, a `WeatherObservation` statistical summary, and a
    `IsFriendOf` relation are quite different at the model level -- they
    represent respectively a tangible Thing, an intangible Thing and a
    non-Thing. But all of them are structured records, with fields an so on.

  - A `FilePath`, a `RawJsonBlob` and a `Url` are all represented as simple
    strings, but each has a distinct semantic meaning, and each implies rules
    that would allow a computer to validate an instance's contents look right.
    
  - We of course use `Array` to hold collections of items, and `Hash` to hold
    labelled collections of items. Wherever possible, we'd like to specify
    "Array of MusicAlbum" and so forth.

Let us now introduce the `Schema`, which characterizes commonalities among `Model` types. 


    <"Torchy's" instance>    manufactured by Restaurant
    <"Torchy's">.menu()      instance methods from Restaurant
    
                             <Restaurant class>                 described by RecordSchema
                             <Restaurant>.field_names           class methods from RecordSchema

A person who find this sort of thing elegant might point out that the
properties of a Schema describe specifics of a model; given values
characterizing those specifics, the Schema manufactures an individual
Model. That is: a Schema is a type for individual Types.

But if you're like me you're better off just remembering 

> Schema == classes and class methods for a type;
> Model  == instances and instance methods for a type.

In implementation land, a Schema is a class, with a distinct existence from its
type. If you're working with types on their own, you want schema objects; 

(In fact, you may discover to your horror that a Schema is itself a RecordType:
it's turtles all the way down.)

### Structured Schema (Array, Map, Enum, Fixed)

#### Meta::ArraySchema

The schema prescribes the *class* of items the `Array` should hold: for example,
an album's `tracks` property is an array of `MusicRecordings`.

    Behavior        Model               Instance Methods        Type                    Class Methods              
    --------------  -----------------   -----------------       ---------------------   ------------------------   
    (superclasses)  Object,Array        ...many...                                      ...many...
    structure type:                                             Meta::BaseType          .metamodel,.to_schema
                                                                Meta::ArrayType         .receive
    metamodel:      --                                          
    model klass:    ArrayOfInt                                  (directly on class)     .items
    
    Schema: class Meta::ArraySchema

For a record model, an individual schema typically doesn't have much to say
about the model class itself. Since models are usually real-world objects we'd
like to handle generically, we focus our interest on fields and instance
methods. An `Array` is something whose *individuals* should be completely
generic: we care about all the interesting things in a list, not the bag that
holds them. The schema for an array (as well as for Hash, Fixed and Enum)
prescribes information about the *type* not the *model*

Now after I just sold you on the virtues of a metamodel in the case of a record,
you might expect an analogous module to extend the class. There's no practical
benefit or need for this, though, so we currently just scribble the .items class
method directly onto the class.

#### Meta::HashSchema

    Behavior        Model               Instance Methods        Type                  Class Methods              
    --------------  -----------------   -----------------       ---------------------   ------------------------   
    (superclasses)  Object,Hash         ...many...                                      ...many...
    structure type:                                             Meta::BaseType          .metamodel,.to_schema
                                                                Meta::HashType          .receive
    metamodel:      --                                          
    model klass:    HashOfYourMom                               (directly on class)     .values  

#### Meta::FixedSchema

    Behavior        Model               Instance Methods        Type                    Class Methods              
    --------------  -----------------   -----------------       ---------------------   ------------------------   
    (superclasses)  Object,String       ...many...                                      ...many...
    structure type:                                             Meta::BaseType          .metamodel,.to_schema
                                                                Meta::FixedType         .receive
    metamodel:      --                                          
    model klass:    Fixed16                                     (directly on class)     .bytesize

#### Meta::EnumSchema

    Behavior        Model               Instance Methods        Type                  Class Methods              
    --------------  -----------------   -----------------       ---------------------   ------------------------   
    (superclasses)  Object,String       ...many...                                      ...many...
    structure type:                                             Meta::BaseType          .metamodel,.to_schema
                                                                Meta::EnumType          .receive
    metamodel:      --                                          
    model klass:    CountryCode                                 (directly on class)     .symbols 


__________________________________________________________________________
__________________________________________________________________________
__________________________________________________________________________

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

