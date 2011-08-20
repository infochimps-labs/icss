module Icss
  module Meta

    module RecordModel
      def self.included(base)
        base.extend(Icss::Meta::RecordType)
        base.metamodel
      end

      #
      # modify object in place with new typecast values.
      #
      def receive!(hsh={})
        raise ArgumentError, "Can't receive (it isn't hashlike): {#{hsh.inspect}}" unless hsh.respond_to?(:[]) && hsh.respond_to?(:has_key?)
        self.class.send(:_rcvr_methods).each do |attr, meth|
          if    hsh.has_key?(attr)      then val = hsh[attr]
          elsif hsh.has_key?(attr.to_s) then val = hsh[attr.to_s]
          else next ; end
          self.send(meth, val)
        end
        run_after_receivers(hsh)
        self
      end

      # true if the attr is a receiver variable and it has been set
      def attr_set?(attr)
        self.class.has_field?(attr) && self.instance_variable_defined?("@#{attr}")
      end

      def unset!(attr)
        self.send(:remove_instance_variable, "@#{attr}") if self.instance_variable_defined?("@#{attr}")
      end
      protected :unset!

    protected

      def run_after_receivers(hsh)
        self.class.after_receivers.each do |after_receiver|
          self.instance_exec(hsh, &after_receiver)
        end
      end

      def _set_field_val(field_name, val)
        self.instance_variable_set("@#{field_name}", val)
      end

    end
  end
end
