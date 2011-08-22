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
