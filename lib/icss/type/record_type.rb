module Icss
  module Meta
    module RecordType
      include ::Icss::Meta::Type
      include ::Icss::Meta::NamedType

      #
      # modify object in place with new typecast values.
      #
      def receive!(hsh={})
        raise ArgumentError, "Can't receive (it isn't hashlike): {#{hsh.inspect}}" unless hsh.respond_to?(:[]) && hsh.respond_to?(:has_key?)
        self.metatype.fields.each do |attr, schema|
          next if schema[:receiver] == :none
          if    hsh.has_key?(attr.to_sym) then val = hsh[attr.to_sym]
          elsif hsh.has_key?(attr.to_s)   then val = hsh[attr.to_s]
          else  next ; end
          self.send("receive_#{attr}", val)
        end
        self.metatype.after_receivers.each do |after_receiver|
          self.instance_exec(hsh, &after_receiver)
        end
        self
      end

      def metatype
        self.class
      end

      module ::Icss::Meta::RecordType::Schema
        include ::Icss::Meta::Type::Schema
        include ::Icss::Meta::NamedType::Schema

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
        #     null          null        NilClass    primitive   nil
        #     boolean       boolean     Boolean     primitive   true
        #     int,long      integer     Integer     primitive   1
        #     float,double  number      Float       primitive   1.1
        #     bytes         string      String      primitive   "\u00FF"
        #     string        string      String      primitive   "foo"
        #     record        object      RecordType  named       {"a": 1}
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
          add_field_schema(field_name, type, schema)
          add_field_accessor(field_name, schema)
          rcvr(field_name, type, schema)
          add_after_receivers(field_name, type, schema)
        end

        def fields
          all_f = @fields || {}
          call_ancestor_chain(:fields){|anc_f| all_f = anc_f.merge(all_f) }
          all_f
        end

        def field_names
          all_f = @field_names || []
          call_ancestor_chain(:field_names){|anc_f| all_f = anc_f | all_f }
          all_f
        end

        def send_rcvr_val(obj, attr, val)
          obj.send("receive_#{attr}", val)
        end

        # So you're asking yourself "Self, why didn't he just call .super?
        # Consider:
        #
        #   class Base
        #     extend(Icss::Meta::RecordType::FieldDecorators)
        #     field :smurfiness, Integer
        #   end
        #   class Poppa < Base
        #     field :height, Integer
        #   end
        #
        # Poppa.field_names calls Icss::Meta::RecordType::FieldDecorators --
        # it's the first member of its inheritance chain to define the method.
        # We want it to do so for each ancestor that has added fields.

        def to_schema
          p [:to_schema, self, __FILE__]
          super.merge(
            :type   => :record,
            :fields => fields.to_hash,
            # :is_a   => ( is_a   || [] ).map{|k| k.fullname },
            )
        end

        # def fields_to_schema
        #   return {} if fields.blank?
        #   ( fields || {} ).map do |fn,fi|
        #     type = fi[:type]
        #     typename = Icss::PRIMITIVE_TYPES.key(type)
        #     p [self, typename, type]
        #     x = typename ? typename : type.to_schema
        #     p x
        #     x
        #   end
        # end


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
          raise ArgumentError, "Can't receive (it isn't hashlike): {#{hsh.inspect}} -- the hsh should be the *last* arg" unless hsh.respond_to?(:[]) && hsh.respond_to?(:has_key?)
          obj = self.new(*args)
          obj.receive!(hsh)
        end

        #
        # define a receiver attribute.
        # automatically generates an attr_accessor on the class if none exists
        #
        # @param  [Symbol]  field_name - name of the receiver property
        # @param  [Class]   type - a
        #
        # @option [Object]  :default  - After any receive! operation, attribute is set to this value unless attr_set? is true
        # @option [Class]   :of       - For collections (Array, Hash, etc), the type of the collection's items
        #
        def rcvr(field_name, type, schema={})
          return if schema[:receiver] == :none
          body = ::Icss::Meta::RecordType.receiver_body_for(type, schema)
          define_method("receive_#{field_name}") do |*args|
            v = body.call(*args)
            self.instance_variable_set("@#{field_name}", v)
            v
          end
        end

        #
        # Defines a receiver for attributes sent to receive! that are
        # * not defined as receivers
        # * field's name does not start with '_'
        #
        # @example
        #     class Foo ; include RecordType
        #       field  :bob, String
        #       rcvr_remaining :other_params
        #     end
        #     foo_obj = Foo.receive(:bob => 'hi, bob", :joe => 'hi, joe')
        #     # => <Foo @bob='hi, bob' @other_params={ :joe => 'hi, joe' }>
        def rcvr_remaining(field_name, schema={})
          field(field_name, Hash, schema)
          after_receive do |hsh|
            remaining_vals_hsh = hsh.reject{|k,v| (receiver_attrs.include?(k)) || (k.to_s =~ /^_/) }
            self.send("receive_#{field_name}", remaining_vals_hsh)
          end
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

        def add_field_schema(name, type, schema)
          @field_names ||= [] ; @fields ||= {}
          @field_names << name unless respond_to?(:field_names) && field_names.include?(name)
          @fields[name] = schema.merge({ :name => name, :type => type })
        end

        def add_field_accessor(name, schema)
          reader_info = schema[:reader] || schema[:accessor]
          writer_info = schema[:writer] || schema[:accessor]
          #
          unless (reader_info == :none)
            attr_reader(name) unless method_defined?(name)
            case reader_info when :protected then protected(name) when :private then private(name) else public(name) end
          end
          unless (writer_info == :none)
            attr_writer(name) unless method_defined?("#{name}=")
            case writer_info when :protected then protected("#{name}=") when :private then private("#{name}=") else public("#{name}=") end
          end
        end

        # yield, in turn, the result of calling the given method on each
        # ancestor that responds. (ancestors are called from parent to
        # great-grandparent)
        def call_ancestor_chain(meth)
          self.ancestors[1..-1].each do |ancestor|
            yield(ancestor.send(meth)) if ancestor.respond_to?(meth)
          end
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
        def add_after_receivers(attr, type, schema)
          if schema.has_key?(:default)
            def_val = schema[:default]
            after_receive do
              self.instance_variable_set("@#{attr}", def_val.try_dup) unless attr_set?(attr)
            end
          end
          if schema.has_key?(:replace)
            repl = schema[:replace]
            after_receive do
              val = self.instance_variable_get("@#{attr}")
              if repl.has_key?(val)
                self.instance_variable_set "@#{attr}", repl[val]
              end
            end
          end
          super(attr, type, schema) if defined?(super)
        end

      end # RecordType::Schema
      def self.included(base) p base ; base.class_eval{ base.extend(Schema) } ; end

      RECEIVER_BODIES           = {} unless defined?(RECEIVER_BODIES)
      RECEIVER_BODIES[NilClass] = lambda{|v| raise ArgumentError, "This field must be nil, but [#{v}] was given" unless (v.nil?) ; nil }
      RECEIVER_BODIES[Boolean]  = lambda{|v| case when v.nil? then nil when v.to_s.strip.blank? then false else v.to_s.strip != "false" end }
      RECEIVER_BODIES[Integer]  = lambda{|v| v.blank? ? nil : v.to_i }
      RECEIVER_BODIES[Float]    = lambda{|v| v.blank? ? nil : v.to_f }
      RECEIVER_BODIES[String]   = lambda{|v| v.to_s }
      #
      RECEIVER_BODIES[Symbol]   = lambda{|v| v.blank? ? nil : v.to_sym }
      RECEIVER_BODIES[Time]     = lambda{|v| v.nil?   ? nil : Time.parse(v.to_s).utc rescue nil }
      RECEIVER_BODIES[Date]     = lambda{|v| v.nil?   ? nil : Date.parse(v.to_s)     rescue nil }
      #
      RECEIVER_BODIES[Object]   = lambda{|v| v } # accept and love the object just as it is
      #
      RECEIVER_BODIES[Array]    = lambda{|v| case when v.nil? then nil when v.blank? then [] else Array(v) end }
      RECEIVER_BODIES[Hash]     = lambda{|v| case when v.nil? then nil when v.blank? then {} else v        end }
      #
      # Give each base class a receive method
      RECEIVER_BODIES.each do |k,b|
        if k.is_a?(Class) && (k != Object)
          k.class_eval{ define_singleton_method(:receive, &b) }
        end
      end

      def self.receiver_body_for type, schema
        # Note that Array and Hash only need (and only get) special treatment when
        # they have an :of => SomeType option.
        case
        when schema[:of] && (type == Array)
          receiver_type = schema[:of]
          lambda{|v|  v.nil? ? nil : v.map{|el| receiver_type.receive(el) } }
        when schema[:of] && (type == Hash)
          receiver_type = schema[:of]
          lambda{|v| v.nil? ? nil : v.inject({}){|h, (el,val)| h[el] = receiver_type.receive(val); h } }
        when RECEIVER_BODIES.include?(type)
          RECEIVER_BODIES[type]
        when type.respond_to?(:receive)
          lambda{|v| v.blank? ? nil : type.receive(v) }
        else
          raise("Can't receive #{type} #{schema}")
        end
      end

    end
  end
end
