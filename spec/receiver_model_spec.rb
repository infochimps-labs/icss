  #   context ':default =>' do
  #     it 'try_dups the object on receipt'
  #     it 'try_dups the object when setting default'
  #     it 'creates an after_receive hook to set the default'
  #     it 'accepts a proc'
  #
  #   end
  #
  #   context ':order =>' do
  #   end
  #
  #   context ':required =>' do
  #     it 'adds a validator'
  #   end
  #
  #   context ':validates' do
  #     context 'length' do
  #       # { :is => :==, :minimum => :>=, :maximum => :<= }.freeze
  #     end
  #
  #     it 'exclusion (on container type)'
  #     it 'format'
  #     it 'numericality' do
  #       # { :greater_than => :>, :greater_than_or_equal_to => :>=, :equal_to => :==, :less_than => :<, :less_than_or_equal_to => :<=, :odd => :odd?, :even => :even? }.freeze
  #     end
  #     it 'presence'
  #     it 'uniqueness'
  #   end
  #
  #   context ':index => ' do
  #     it 'primary key'
  #     it 'foreign key'
  #     it 'uniqueness constraint'
  #   end
  #
  #   # context ':accessor / :reader / :writer' do
  #   #   it ':private         -- attr_whatever is private'
  #   #   it ':protected       -- attr_whatever is protected'
  #   #   it ':none            -- no accessor/reader/writer'
  #   # end
  #
  #   context ':after_receive'
  #
  #   context ':i18n_key'
  #   context ':human_name => '
  #   context ':singular_name => '
  #   context ':plural_name => '
  #   context ':uncountable => '
  #
  #   context :serialization
  #   it '#serializable_hash'
  #
  #   # constant
  #   # mass assignment security: accessible,
  #
  #   it 'works on the parent Meta module type, not '
  #

  # context 'has properties' do
  #   it 'described by its #fields'
  #
  #   context 'container types' do
  #
  #     it 'field foo, Array, :items   => FooClass validates instances are is_a?(FooClass)'
  #     it 'field foo, Array, :with => FooFactory validates instances are is_a?(FooFactory.product_klass)'
  #
  #     it ''
  #
  #   end
  # end
  #
  # context 'special properties' do
  #   it '_domain_id_field'
  #   it '_primary_location_field'
  #   it '_slug' # ??
  # end
  #
  # context 'name' do
  #   context ':i18n_key'
  #   context ':human_name => '
  #   context ':singular_name => '
  #   context ':plural_name => '
  #   context ':uncountable => '
  # end
