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

#### Container Schema (Array, Map)

#### Named Schema (Enum, Fixed)


#### Record
* primitive types are also simple types

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

