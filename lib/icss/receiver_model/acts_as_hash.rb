require 'gorillib/hashlike'

module Icss
  module ReceiverModel

    #
    # Makes an Icss::RecordModel behave mostly like a hash.
    #
    # By default, the hashlike methods iterate over the fields: instance #keys
    # delegates to self.class.field_names. All methods are defined naturally on
    # [], []= and has_key? so the interface is well-guarded.
    #
    # in addition to the below, by including Enumerable, this also adds
    #
    #     :each_cons, :each_entry, :each_slice, :each_with_index, :each_with_object,
    #     :map, :collect, :collect_concat, :entries, :to_a, :flat_map, :inject, :reduce,
    #     :group_by, :chunk, :cycle, :partition, :reverse_each, :slice_before, :drop,
    #     :drop_while, :take, :take_while, :detect, :find, :find_all, :find_index, :grep,
    #     :all?, :any?, :none?, :one?, :first, :count, :zip :max, :max_by, :min, :min_by,
    #     :minmax, :minmax_by, :sort, :sort_by
    #
    # As opposed to hash, does *not* define
    #
    #   default, default=, default_proc, default_proc=, shift, flatten, compare_by_identity
    #   compare_by_identity? rehash
    #
    module ActsAsHash

      # Hashlike#[]
      #
      # Element Reference -- Retrieves the value stored for +key+.
      #
      # In a normal hash, a default value can be set; none is provided here.
      #
      # Delegates to self.send(key)
      #
      # @example
      #     hsh = { :a => 100, :b => 200 }
      #     hsh[:a] # => 100
      #     hsh[:c] # => nil
      #
      # @param  key [Object] key to retrieve
      # @return [Object] the value stored for key, nil if missing
      #
      def [](key)
        key = convert_key(key)
        self.send(key)
      end

      # Hashlike#[]=
      # Hashlike#store
      #
      # Element Assignment -- Associates the value given by +val+ with the key
      # given by +key+.
      #
      # key should not have its value changed while it is in use as a key. In a
      # normal hash, a String passed as a key will be duplicated and frozen. No such
      # guarantee is provided here
      #
      # Delegates to self.send("key=", val)
      #
      # @example
      #     hsh = { :a => 100, :b => 200 }
      #     hsh[:a] = 9
      #     hsh[:c] = 4
      #     hsh    # => { :a => 9, :b => 200, :c => 4 }
      #
      #     hsh[key] = val                         -> val
      #     hsh.store(key, val)                    -> val
      #
      # @param  key [Object] key to associate
      # @param  val [Object] value to associate it with
      # @return [Object]
      #
      def []=(key, val)
        key = convert_key(key)
        self.send("#{key}=", val) if respond_to?("#{key}=")
        val
      end

      # Hashlike#delete
      #
      # Deletes and returns the value from +hsh+ whose key is equal to +key+. If the
      # optional code block is given and the key is not found, pass in the key and
      # return the result of +block+.
      #
      # In a normal hash, a default value can be set; none is provided here.
      #
      # @example
      #     hsh = { :a => 100, :b => 200 }
      #     hsh.delete(:a)                            # => 100
      #     hsh.delete(:z)                            # => nil
      #     hsh.delete(:z){|el| "#{el} not found" }   # => "z not found"
      #
      # @overload hsh.delete(key)                  -> val
      #   @param  key [Object] key to remove
      #   @return [Object, Nil] the removed object, nil if missing
      #
      # @overload hsh.delete(key){|key| block }    -> val
      #   @param  key [Object] key to remove
      #   @yield  [Object] called (with key) if key is missing
      #   @yieldparam key
      #   @return [Object, Nil] the removed object, or if missing, the return value
      #     of the block
      #
      def delete(key, &block)
        key = convert_key(key)
        if has_key?(key)
          val = self[key]
          self.send(:remove_instance_variable, "@#{key}")
          val
        elsif block_given?
          block.call(key)
        else
          nil
        end
      end

      # Hashlike#keys
      #
      # Returns a new array populated with the keys from this hashlike.
      #
      # @see Hashlike#values.
      #
      # @example
      #     hsh = { :a => 100, :b => 200, :c => 300, :d => 400 }
      #     hsh.keys   # => [:a, :b, :c, :d]
      #
      # @return [Array] list of keys
      #
      def keys
        self.class.field_names & instance_variables.map{|s| convert_key(s[1..-1]) }
      end

      #
      # Returns a hash with each key set to its associated value.
      #
      # @example
      #    my_hshlike = MyHashlike.new
      #    my_hshlike[:a] = 100; my_hshlike[:b] = 200
      #    my_hshlike.to_hash # => { :a => 100, :b => 200 }
      #
      # @return [Hash] a new Hash instance, with each key set to its associated value.
      #
      def attributes
        {}.tap do |hsh|
          each_pair do |key, val|
            hsh[key] = val.respond_to?(:to_hash) ? val.to_hash : val
          end
        end
      end

      #
      # Returns a hash with each key set to its associated value.
      #
      # Delegates to #attributes
      #
      def to_hash
        attributes
      end

      def self.included(base)
        base.class_eval do
          include Gorillib::Hashlike
        end
      end

    protected

      def convert_key(key)
        raise ArgumentError, "Keys for #{self.class} must be symbols, strings or respond to #to_sym" unless key.respond_to?(:to_sym)
        key.to_sym
      end
    end

  end
end
