# The Infochimps Stupid Schema (ICSS)

An ICSS file is a *complete*, *expressive* description of a collection of related data and all associated assets. It is based on the [Avro Protocol](http://avro.apache.org/docs/current/index.html) specification, with some necessary extensions


___________________________________________________________________________
<a name="model" >
## Icss::ReceiverModel -- a pragmatic, flexible framework for active structured data
### (or: How to Be Object-Oriented in a JSON World)

`Icss::ReceiverModel` 


The real power is in the intelligent type delegation:

```ruby
    class Thing
      include Icss::ReceiverModel
      field :name, String
      field :description, String
    end
    
    class GeoCoordinates
      include Icss::ReceiverModel
      field :latitude,  Float, :validates => { :numericality => { :>= =>  -90, :<= =>  90  } }
      field :longitude, Float, :validates => { :numericality => { :>= => -180, :<= => 180  } }
      def coordinates
        [ longitude, latitude ]
      end
    end
    
    class Place < Thing
      field :geo, GeoCoordinates
    end
    
    class MenuItem < Thing
      field :price, Float, :required => true
    end

    class Restaurant < Place
      field :menu, Array, :items => MenuItem
    end
    
    torchys = Restaurant.receive({
      :name => "Torchy's Taco's",
      :menu => [ 
        { :name => "Dirty Sanchez", :price => "6.95" }, 
        { :name => "Fried Avocado", :price => "7.35" }
      ],
      :geo  => { :longitude => 30.295, :latitude => -97.745 },
    })
    # #<Restaurant:0x00000101d539f8 @name="Torchy's Taco's", 
    #   @geo=#<GeoCoordinates:0x00000101d53318 @latitude=-97.745, @longitude=30.295>,
    #   @menu=[ #<MenuItem:0x00000101d51180 @name="Dirty Sanchez", @price=6.95>, 
    #           #<MenuItem:0x00000101d4d468 @name="Fried Avocado", @price=7.35>  ]>

    torchys.geo.coordinates
    # [ 30.295, -97.745 ]

    torchys.to_hash
    # {:name=>"Torchy's Taco's", 
    #   :geo=>{:latitude=>-97.745, :longitude=>30.295}, 
    #   :menu=>[#<MenuItem:0x00000101d452b8 @name="Dirty Sanchez", @price=6.95>, #<MenuItem:0x00000101d44a98 @name="Fried Avocado", @price=6.3>]}


```

### declaring fields

Declaring a field constructs the following. Taking 

```ruby
    field :foo, Array, :items => :int
```

* accessors       -- `#foo` and `foo=` getter/setters. These are completely regular accessors: no type checking/conversion/magic happens when the object is in regular use. 
* receiver        -- a `receive_foo` method that provides lightweight type coercion
* field schema    -- a `RecordField` object describing the field, available through the `.fields` class method. You can send this schema over the wire (in JSON or whatever) and use it to recapitulate the type elsewhere.
* hashlike access -- retrieve a value with `object[:foo]`, or set it with `object[:foo] = 7`. 

Optionally, you can decorate with 
* rcvr_remaining -- a catchall field for anything `receive!`d that wasn't predicted by the schema.
* validations  -- the full set of ActiveModel validations
* after_receive hooks -- including default value

### Predictable magic

Magic *only* happens in the neighborhood of `receive` methods. 
* The initializer, getter/setter, and so forth are non-magical. 
* Validation is only done on request, and type conversion when `receive_foo` is invoked.
* Hashlike access is only for defined fields

### receive methods

You can make a new ojbect using `Smurf.receive({...})`, which is exactly equivalent to calling each of `obj = Smurf.new ; obj.receive!({...}) ; obj` in turn.

* The 

### Hashlike

* .

### validations

Add ActiveModel validations with the `:validates` option to `.field`, or directly using `.validates`:

```ruby
    class Icss::Handy
      include Icss::ReceiverModel
      field :rangey,     Integer, :validates => { :inclusion => { :in => 0..9 }}
      field :patternish, String
      field :mandatory,  Integer, :required => true
      validates :patternish, :format => { :with => /eat$/ }
    end
    good_smurf = Icss::Handy.receive(:rangey => 5, :patternish => 'smurfberry crunch is fun to eat', :mandatory => 1)
    bad_smurf  = Icss::Handy.receive(:rangey => 3, :patternish => 'smurfnuggets!')
    good_smurf.valid? # true
    bad_smurf.valid?  # false
    bad_smurf.errors  # { :mandatory  => ["can't be blank"], :patternish => ["is invalid"] }
```

As shown, you can also say `:required => true` as a shorthand for `:validates => { :presence => true }`. A summary of the other `:validates` directives:

```
    :presence     => true
    :uniqueness   => true
    :numericality => true           # also :==, :>, :>=, :<, :<=, :odd?, :even?, :equal_to, :less_than, etc
    :length       => { :<  => 7 }   # also :==, :>=, :<=, :is, :minimum, :maximum
    :format       => { :with => /.*/ }
    :inclusion    => { :in => [1,2,3] }
    :exclusion    => { :in => [1,2,3] }
```

### rcvr_remaining

`rcvr_remaining` creates a Hash field to catch all attributes send to `receive!` that don't match any receiver fields. This is surprisingly useful.

Note that you can feed `rcvr_remaining` a `:values` option if you want type coercion on the extra params.

### rcvr_alias

`rcvr_alias` will redirect an attribute to a different receiver:

```ruby
    class Wheel
      include Icss::ReceiverModel
      field      :name,          String
      field      :center_height, Float
      rcvr_alias :centre_height, :center_height
    end
    foo = Wheel.receive(:name => 'tyre', :centre_height => 18.2)
    foo.center_height               # 18.2
    foo.respond_to?(:centre_height) # false
```   

Notes:

* It does not make any other methods, only a `receive_(fake)` that calls the `receive_(target)` method.
* It makes no special provisions for both attributes being received.

### after_receive

`after_receive(:hook_name){ ... }` creates a named hook, executed at the end of `receive!` (and similar actions). Some examples:

```ruby
    after_receive(:warnings) do |hsh|
      warn "Validation failed for field #{self}: #{errors.inspect}" if respond_to?(:errors) && (not valid?)
    end
    after_receive(:generate_id) do |hsh|
      if !attr_set?(:md5id) then self.md5id = Digest::MD5.hex_digest(name) ; end
    end    
```

Notes:
* Make sure your `after_receive` blocks are _idempotent_ -- that is, that re-running the block has no effect. Lots of things are allowed to trigger `run_after_receivers`.

### field :default => val

You can use the `:default` option to `field` (or call `.set_field_default` directly) to specify a default value when the field is empty after a `receive!`.

```
    class Icss::Smurf
      field :tool,    Symbol, :default => :smurfwrench
      field :weapon,  Symbol, :default => :smurfthrower
    end
    
    # default set for missing attributes
    handy_smurf = Icss::Smurf.receive( :tool => :pipesmurf )
    handy_smurf.weapon # :smurfthrower
    
    # if an attribute is set-but-nil no default is applied
    handy_smurf = Icss::Smurf.receive( :tool => :smurfwrench, :weapon => nil )
    handy_smurf.weapon # nil
    
    # you can also use a block; it is `instance_eval`ed for the value to set.
    Icss::Smurf.field(:food, Symbol, :default => 
      lambda{ (weapon.to_s =~ /^smurf/) ? :smurfed_cheese : :grilled_smurf }
    brainy_smurf = Icss::Smurf.receive( :weapon => :smurfapult    )
    hefty_smurf  = Icss::Smurf.receive( :weapon => :gatling_smurf )
    brainy_smurf.food # :smurfed_cheese
    hefty_smurf.food  # :grilled_smurf
```

Note:
* If a value is explicitly `nil`, the default is not applied.
* You may specify a block (as shown); the attribute is set to the result of `instance_eval`ing the block.
* Defaults do *not* applied at initialization -- only when `run_after_receivers` is triggered. (so, the `receive` operation is complete).
* The run order will be dependable on ruby >= 1.9 but not on 1.8.x.



___________________________________________________________________________
<a name="avro" >
## Avro Protocol, Message, RecordType and Field


    avro        kind        ruby           json      example                schema example
    ---------   ---------   ------------   -------   ---------              --------------
    null        base        NilClass       null      nil                    'null'
    boolean     base        Boolean        boolean   true                   'boolean'
    int         base        Integer        integer   1                      'int'
    long        base        Long           integer   1                      'long'
    float       base        Float          number    1.1                    'float'
    double      base        Double         number    1.1                    'double'
    bytes       base        Binary         string    "\u00FF"               'bytes'
    string      base        String         string    "foo"                  'string'
    time        base        Time           string    "2011-01-02T03:04:05Z" 'time'
    symbol      base        Symbol         string    :belongs_to            'symbol'

    array       structured  (ArrayOfXXX)   array     [1,2]                  { 'type': 'array',  'items':  'int' }
    map         structured  (HashOfXXX)    object    { "a": 1 }             { 'type': 'map',    'values': 'int' }

    enum        named       (EnumType)     string    "heads"                { 'type': 'enum',   'name': 'result', 'symbols': ['heads','tails'] }
    fixed       named       (FixedType)    string    "\xBD\xF3)Q"           { 'type': 'fixed',  'name': 'crc32',  'length': 4 }
    record      named       (RecordType)   object    {"a": 1}               { 'type': 'record', 'name': 'bob',    'fields':[...] }
    error       named       (ErrorType)    object    {"err":halp! fire!"}   { 'type': 'record', 'name': 'db_on_fire, 'fields':[...] }

    union       union       <UnionType>    object                           [ 'long', { 'type': 'array', 'items': 'int' } ]

    st.regexp   simple      St::Regexp     string    "^hel*o newman"        'regexp'
    st.url      simple      St::Url        string    "http://..."           'url'
    mu.epoch_time simple    Mu::EpochTime  string    1312507492             'epoch_time'



#### Base (int, float, string, ...)

A `:base` type in an Icss file 

Class `.receive` method is just `new` (where appropriate) with the appropriate conversion. Receiving `nil` returns `nil` without error.

Note that some of the base types are *not* present in the Avro spec.

__________________________________________________________________________
__________________________________________________________________________
__________________________________________________________________________

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

