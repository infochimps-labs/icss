module Icss
  module ReceiverModel
    module ActsAsReceiver

      #
      # modify object in place with new typecast values.
      #
      def receive!(hsh={})
        raise ArgumentError, "Can't receive (it isn't hashlike): {#{hsh.inspect}}" unless hsh.respond_to?(:[]) && hsh.respond_to?(:has_key?)
        fields.each do |attr, field_info|
          next if field_info[:receiver] == :none
          if    hsh.has_key?(attr.to_sym) then val = hsh[attr.to_sym]
          elsif hsh.has_key?(attr.to_s)   then val = hsh[attr.to_s]
          else  next ; end
          _receive_attr attr, val
        end
        run_after_receivers(hsh)
        self
      end

      # true if the attr is a receiver variable and it has been set
      def attr_set?(attr)
        receiver_attrs.has_key?(attr) && self.instance_variable_defined?("@#{attr}")
      end

      def unset!(attr)
        self.send(:remove_instance_variable, "@#{attr}") if self.instance_variable_defined?("@#{attr}")
      end
      protected :unset!

      def to_tuple
        tuple = []
        self.each_value do |val|
          if val.respond_to?(:to_tuple)
            tuple += val.to_tuple
          else
            tuple << val
          end
        end
        tuple
      end

      def _receive_attr(attr, val)
        self.send("receive_#{attr}", val)
      end
      protected :_receive_attr

      def run_after_receivers(hsh)
        self.class.after_receivers.each do |after_receiver|
          self.instance_exec(hsh, &after_receiver)
        end
      end
      protected :run_after_receivers

      module ClassMethods

        #
        # Describes a field in a Record object.
        #
        # Each field has the following attributes:
        #
        # @param [Symbol] field_name -- a string providing the name of the field
        #   (required)
        #
        # @param [Class, Icss::Type] type a schema, or a string or symbol
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
        #     array         array       Array       enumerable  [1]
        #     map           object      Hash        enumerable  { "a": 1 }
        #     fixed         string      String      enumerable  "\u00ff"
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
        # @option field_info [String] :doc -- description of field for users (optional)
        #
        # @option field_info [Object] :default -- a default value for this field, used
        #   when reading instances that lack this field (optional).
        #   Permitted values depend on the field's schema type, according to the
        #   table below. Default values for union fields correspond to the first
        #   schema in the union. Default values for bytes and fixed fields are
        #   JSON strings, where Unicode code points 0-255 are mapped to unsigned
        #   8-bit byte values 0-255.
        #
        # @option field_info [String] :order -- specifies how this field impacts sort
        #   ordering of this record (optional).
        #   Valid values are "ascending" (the default), "descending", or
        #   "ignore". For more details on how this is used, see the the sort
        #   order section below.
        #
        # @option field_info [Boolean] :required -- same as :validates => :presence
        #
        # @option field_info [Symbol] :accessor -- with +:none+, no accessor is
        #   created. With +:protected+, +:private+, or +:public+, applies
        #   corresponding access rule.
        #
        # @option field_info [Symbol] :reader -- with +:none+, no reader is
        #   created. With +:protected+, +:private+, or +:public+, applies
        #   corresponding access rule.
        #
        # @option field_info [Symbol] :writer -- with +:none+, no writer is
        #   created. With +:protected+, +:private+, or +:public+, applies
        #   corresponding access rule.
        #
        # @option field_info [Hash] :validates -- sends the validation on to
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
        def field(field_name, type, field_info={})
          field_name = field_name.to_sym
          super(field_name, type, field_info)
          add_receiver(field_name, type, field_info)
          add_after_receivers(field_name, type, field_info)
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
        def add_receiver(field_name, type, field_info={})
          return if field_info[:receiver] == :none
          body = ReceiverDecorators.receiver_body_for(type, field_info)
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
        #     class Foo ; include Receiver
        #       rcvr_accessor  :bob, String
        #       rcvr_remaining :other_params
        #     end
        #     foo_obj = Foo.receive(:bob => 'hi, bob", :joe => 'hi, joe')
        #     # => <Foo @bob='hi, bob' @other_params={ :joe => 'hi, joe' }>
        def rcvr_remaining(field_name, field_info={})
          field(field_name, Hash, field_info)
          after_receive do |hsh|
            remaining_vals_hsh = hsh.reject{|k,v| (receiver_attrs.include?(k)) || (k.to_s =~ /^_/) }
            self._receive_attr(field_name, remaining_vals_hsh)
          end
        end

        # returns a depth-first traversal of the object's fields' keys, as Strings:
        #
        #   class Address < Icss::Thing
        #     field(:housenum, Integer)
        #     field(:street, String)
        #   end
        #   class Person <  Icss::Thing
        #     field(:full_name, String)
        #     field(:street_address, Address)
        #   end
        #   Person.tuple_keys
        #   # => ['street_address.housenum', 'street_address.street', 'fullname']
        def tuple_keys
          return @tuple_keys if @tuple_keys
          @tuple_keys = fields.map do |attr, field_info|
            if field_info[:type].respond_to?(:tuple_keys)
              field_info[:type].tuple_keys.map{|k| "attr.#{k}" }
            else
              attr.to_s
            end
          end.flatten
        end

        # walks through the tuple, destructively consuming each value in a
        # depth-first walk of the field tree:
        #
        #   class Address < Icss::Thing
        #     field(:housenum, Integer)
        #     field(:street, String)
        #   end
        #   class Person <  Icss::Thing
        #     field(:full_name, String)
        #     field(:street_address, Address)
        #   end
        #   Person.consume_tuple(1214, 'W 6th St', 'Joe the Chimp')
        #   # => #<Person street_address=#<Address housenum=1214, street='W 6th St'>, fullname='Joe the Chimp'>
        #
        def consume_tuple(tuple)
          obj = self.new
          fields.each do |attr, field_info|
            if field_info[:type].respond_to?(:consume_tuple)
              val = field_info[:type].consume_tuple(tuple)
            else
              val = tuple.shift
            end
            # obj.send("receive_#{attr}", val)
            obj.send("#{attr}=", val)
          end
          obj
        end

        protected

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
        RECEIVER_BODIES[Hash]     = lambda{|v| case when v.nil? then nil when v.blank? then {} else v end }
        #
        # Give each base class a receive method
        RECEIVER_BODIES.each do |k,b|
          if k.is_a?(Class)
            k.class_eval{ define_singleton_method(:receive, &b) }
          end
        end

        def self.receiver_body_for type, field_info
          type = type_to_klass(type)
          # Note that Array and Hash only need (and only get) special treatment when
          # they have an :of => SomeType option.
          case
          when field_info[:of] && (type == Array)
            receiver_type = field_info[:of]
            lambda{|v|  v.nil? ? nil : v.map{|el| receiver_type.receive(el) } }
          when field_info[:of] && (type == Hash)
            receiver_type = field_info[:of]
            lambda{|v| v.nil? ? nil : v.inject({}){|h, (el,val)| h[el] = receiver_type.receive(val); h } }
          when Receiver::RECEIVER_BODIES.include?(type)
            Receiver::RECEIVER_BODIES[type]
          when type.is_a?(Class)
            lambda{|v| v.blank? ? nil : type.receive(v) }
          else
            raise("Can't receive #{type} #{field_info}")
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

        # Adds after_receivers to implement some of the options to .field
        #
        # @option field_info [Object] :default -- if field is unset by time of
        #   after_receive, the field will be set to a copy of this value
        #
        # @option field_info [Hash] :replace -- if value is in the hash
        #   class Foo < Icss::Thing
        #     field :temperature, Integer, :replace => { 9999 => nil }
        #   end
        #   f = Foo.receive({:temperature => 9999})
        #   # #<Foo:0x10156c820 @temperature=nil>
        #
        def add_after_receivers(attr, type, field_info)
          if field_info.has_key?(:default)
            def_val = field_info[:default]
            after_receive do
              self.instance_variable_set("@#{attr}", def_val.try_dup) unless attr_set?(attr)
            end
          end
          if field_info.has_key?(:replace)
            repl = field_info[:replace]
            after_receive do
              val = self.instance_variable_get("@#{attr}")
              if repl.has_key?(val)
                self.instance_variable_set "@#{attr}", repl[val]
              end
            end
          end
          super(attr, type, field_info) if defined?(super)
        end

      end
    end
  end
end
