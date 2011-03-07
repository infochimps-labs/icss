module Receiver

  #
  # Makes a Receiver thingie behave mostly like a hash.
  #
  module ActsAsHash
    def to_hash
      self.class.receiver_attr_names.inject({}) do |h,name|
        val = self.send(name)
        h[name] = (val.respond_to?(:to_hash) ? val.to_hash : val) if val
        h
      end
    end

    # Fake hash reader semantics
    #
    # Note: indifferent access -- either of :foo or "foo" will work
    def [](name)
      self.send(name)
    end

    # Fake hash writer semantics
    #
    # NOTE: this calls self.foo= 5, not self.receive_foo(5) --
    #   only one layer of sugar at a time, sweetie.
    #
    # Note: indifferent access -- either of :foo or "foo" will work
    def []=(name, val)
      self.send("#{name}=", val)
    end
  end


end
