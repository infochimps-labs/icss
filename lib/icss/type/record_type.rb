require 'icss/type/type_factory'

module Icss
  module Meta

    #
    # RecordType -- class methods for a RecordModel
    #
    # Endows the model class with
    # * klass.field  -- adds a field
    # * klass.fields -- list of record_fields
    #
    # * klass.after_receive(&blk) -- blocks to execute after .receive is called
    # * klass.after_receivers     -- list of after_receivers
    # * klass.metamodel           -- overlay module that actually carries the model's instance methods
    # * klass.to_schema           --
    module RecordType
      include Icss::Meta::NamedType

      #
      # Returns a new instance with the given hash used to set all rcvrs.
      #
      # All args up to the last one are passed to the initializer.
      # The last arg must be a hash -- its attributes are set on the newly-created object
      #
      # @param hsh [Hash] attr-value pairs to set on the newly created object.
      # @param *args [Array] arguments to pass to the constructor
      # @return [Object] a new instance
      def receive *args
        hsh = args.pop
        raise ArgumentError, "#{self} can't receive '#{hsh.inspect}' (it isn't hashlike)" unless hsh.respond_to?(:[]) && hsh.respond_to?(:has_key?)
        obj = self.new(*args)
        obj.receive!(hsh)
      end

      #
      # Describes a field in a Record object.
      #
      # Each field has the following attributes:
      #
      # @param [Symbol] name -- a string providing the name of the field
      #   (required)
      #
      # @param [Class, Icss::Meta::Type] type a schema, or a string or symbol
      #   naming a record definition (required)
      #
      #     avro type     json type   ruby type   kind        example
      #     ---------     ---------   ----------  --------    ---------
      #     null          null        NilClass    simple   nil
      #     boolean       boolean     Boolean     simple   true
      #     int,long      integer     Integer     simple   1
      #     float,double  number      Float       simple   1.1
      #     bytes         string      String      simple   "\u00FF"
      #     string        string      String      simple   "foo"
      #     record        object      RecordModel  named       {"a": 1}
      #     enum          string      Enum        named       "FOO"
      #     array         array       Array       container  [1]
      #     map           object      Hash        container  { "a": 1 }
      #     fixed         string      String      container  "\u00ff"
      #     union         object      XxxFactory  union
      #
      #     date          string      Date        simple      "2011-01-02"
      #     time          string      Time        simple      "2011-01-02T03:04:05Z"
      #     text          string      Text        simple      "long text"
      #     file_path     string      FilePath    simple      "/tmp/foo"
      #     regexp        string      Regexp      simple      "^hel*o newman"
      #     url           string      Url         simple      "http://..."
      #     epoch_time    string      EpochTime   simple      1312507492
      #
      # @option schema [String] :doc -- description of field for users (optional)
      #
      # @option schema [Object] :default -- a default value for this field, used
      #   when reading instances that lack this field (optional).
      #   Permitted values depend on the field's schema type, according to the
      #   table below. Default values for union fields correspond to the first
      #   schema in the union. Default values for bytes and fixed fields are
      #   JSON strings, where Unicode code points 0-255 are mapped to unsigned
      #   8-bit byte values 0-255.
      #
      # @option schema [String] :order -- specifies how this field impacts sort
      #   ordering of this record (optional).
      #   Valid values are "ascending" (the default), "descending", or
      #   "ignore". For more details on how this is used, see the the sort
      #   order section below.
      #
      # @option schema [Boolean] :required -- same as :validates => :presence
      #
      # @option schema [Symbol] :accessor -- with +:none+, no accessor is
      #   created. With +:protected+, +:private+, or +:public+, applies
      #   corresponding access rule.
      #
      # @option schema [Symbol] :reader -- with +:none+, no reader is
      #   created. With +:protected+, +:private+, or +:public+, applies
      #   corresponding access rule.
      #
      # @option schema [Symbol] :writer -- with +:none+, no writer is
      #   created. With +:protected+, +:private+, or +:public+, applies
      #   corresponding access rule.
      #
      # @option schema [Hash] :validates -- sends the validation on to
      #   Icss::Type::Validations. Uses syntax parallel to ActiveModel's:
      #
      #      :presence     => true
      #      :uniqueness   => true
      #      :numericality => true
      #      :length       => { :minimum => 0, maximum => 2000 }
      #      :format       => { :with => /.*/ }
      #      :inclusion    => { :in => [1,2,3] }
      #      :exclusion    => { :in => [1,2,3] }
      #
      def field(field_name, type, schema={})
        field_name = field_name.to_sym
        #
        add_field_schema(field_name, type, schema)
        add_field_accessor(field_name, schema)
        rcvr(field_name, type, schema)
      end

      def field_names
        all_f = @field_names || []
        call_ancestor_chain(:field_names){|anc_f| all_f = anc_f | all_f }
        all_f
      end

      def fields
        field_schemas.values_at(*field_names)
      end

      def field_named(fn)
        field_schemas[fn]
      end

      def has_field?(fn)
        !! field_schemas.has_key?(fn.to_sym)
      end

      #
      # define a receiver attribute.
      #
      # @param  [Symbol]  field_name - name of the receiver property
      # @param  [Class]   type - a
      #
      # @option [Object]  :default  - After any receive! operation, attribute is set to this value unless attr_set? is true
      # @option [Class]   :items       - For collections (Array, Hash, etc), the type of the collection's items
      #
      def rcvr(field_name, type, schema={})
        return if schema[:receiver] == :none
        klass = Icss::Meta::TypeFactory.receive(schema.merge( :type => type ))
        rcvr_meth = "receive_#{field_name}"
        define_metamodel_method(rcvr_meth) do |val|
          _set_field_val(field_name, klass.receive(val))
        end
        _register_rcvr_for(field_name, rcvr_meth)
        add_after_receivers(field_name, type, schema)
      end

      def rcvr_alias(fake_attr, field_name)
        _register_rcvr_for(fake_attr, "receive_#{field_name}")
      end

      #
      def to_schema
        #(defined?(super) ? super() : {}).merge(
        ({
          :name   => fullname,
          :type   => :record,
          :doc    => doc,
          :fields => fields.map(&:to_hash),
          :is_a   => (respond_to?(:is_a) ? is_a : []),
         }).compact_blank
      end

      #
      # Defines a receiver for attributes sent to receive! that are
      # * not defined as receivers
      # * field's name does not start with '_'
      #
      # @example
      #     class Foo ; include RecordModel
      #       field  :bob, String
      #       rcvr_remaining :other_params
      #     end
      #     foo_obj = Foo.receive(:bob => 'hi, bob", :joe => 'hi, joe')
      #     # => <Foo @bob='hi, bob' @other_params={ :joe => 'hi, joe' }>
      def rcvr_remaining(field_name, schema={})
        field(field_name, Hash, schema )
        after_receive do |hsh|
          hsh.symbolize_keys!
          remaining_vals_hsh = hsh.reject{|k,v| (self.class.has_field?(k)) || (k.to_s =~ /^_/) }
          self.send("receive_#{field_name}", remaining_vals_hsh)
        end
        add_after_receivers(field_name, Hash, schema)
      end

      # make a block to run after each time  .receive! is invoked
      def after_receive &block
        @after_receivers = (@after_receivers || []) | [block]
      end

      # after_receive blocks for self and all ancestors
      def after_receivers
        all_f = @after_receivers || []
        call_ancestor_chain(:after_receivers){|anc_f| all_f = anc_f | all_f }
        all_f
      end

    protected

      #
      # yield, in turn, the result of calling the given method on each
      # ancestor that responds. (ancestors are called from parent to
      # great-grandparent)
      #
      # So you're asking yourself "Self, why not just call .super?
      #
      # Consider:
      #
      #   class Base
      #     extend(Icss::Meta::RecordType)
      #     field :smurfiness, Integer
      #   end
      #   class Poppa < Base
      #     field :height, Integer
      #   end
      #
      # Poppa.field_names calls Icss::Meta::RecordType --
      # it's the first member of its inheritance chain to define the method.
      # We want it to do so for each ancestor that has added fields.
      def call_ancestor_chain(meth)
        self.ancestors[1..-1].each do |ancestor|
          yield(ancestor.send(meth)) if ancestor.respond_to?(meth)
        end
      end

      def empty_field_schema
        Hash.new
      end

      def field_schemas
        all_f = @field_schemas || {}
        call_ancestor_chain(:field_schemas){|anc_f| all_f = anc_f.merge(all_f) }
        all_f
      end

      # register the field schema internally.
      # To preserve field order for 1.8.7, we track field names as an array
      def add_field_schema(name, type, schema)
        @field_names ||= [] ; @field_schemas ||= {}
        schema = schema.symbolize_keys.merge({ :name => name, :type => type })
        @field_names         = @field_names | [name]
        @field_schemas[name] = (field_schemas[name] || empty_field_schema).merge(schema)
      end

      def add_field_accessor(field_name, schema)
        visibility = schema[:accessor] || :public
        reader_meth = field_name ; writer_meth = "#{field_name}=" ; attr_name = "@#{field_name}"
        unless (visibility == :none)
          define_metamodel_method(reader_meth, visibility){    instance_variable_get(attr_name)    }
          define_metamodel_method(writer_meth, visibility){|v| instance_variable_set(attr_name, v) }
        end
      end

      def _rcvr_methods
        all_f = @_rcvr_methods || {}
        call_ancestor_chain(:_rcvr_methods){|anc_f| all_f = anc_f.merge(all_f) }
        all_f
      end

      def _register_rcvr_for(attr_name, rcvr_meth)
        @_rcvr_methods ||= {}
        @_rcvr_methods[attr_name.to_sym] = rcvr_meth.to_sym
      end

      # Adds after_receivers to implement some of the options to .field
      #
      # @option schema [Object] :default -- if field is unset by time of
      #   after_receive, the field will be set to a copy of this value
      #
      # @option schema [Hash] :replace -- if value is in the hash
      #   class Foo < Icss::Thing
      #     field :temperature, Integer, :replace => { 9999 => nil }
      #   end
      #   f = Foo.receive({:temperature => 9999})
      #   # #<Foo:0x10156c820 @temperature=nil>
      #
      def add_after_receivers(field_name, type, schema)
        if schema.has_key?(:default)
          def_val = schema[:default]
          after_receive do
            self._set_field_val(field_name, def_val.try_dup) unless attr_set?(field_name)
          end
        end
        if schema.has_key?(:replace)
          repl = schema[:replace]
          after_receive do
            val = self.send(field_name)
            if repl.has_key?(val)
              self._set_field_val(field_name, repl[val])
            end
          end
        end
        super(field_name, type, schema) if defined?(super)
      end

    end # RecordType
  end
end
