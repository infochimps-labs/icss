module Icss
  module Meta

    module RecordModel
      def self.included(base) base.extend(Icss::Meta::RecordType) ; end

      #
      # modify object in place with new typecast values.
      #
      def receive!(hsh={})
        raise ArgumentError, "Can't receive (it isn't hashlike): {#{hsh.inspect}}" unless hsh.respond_to?(:[]) && hsh.respond_to?(:has_key?)
        self.class.fields.each do |attr, field_schema|
          rcv_method = "receive_#{attr}"
          next unless self.respond_to?(rcv_method)
          if    hsh.has_key?(attr.to_sym) then val = hsh[attr.to_sym]
          elsif hsh.has_key?(attr.to_s)   then val = hsh[attr.to_s]
          else  next ; end
          self.send(rcv_method, val)
        end
        run_after_receivers(hsh)
        self
      end

      # true if the attr is a receiver variable and it has been set
      def attr_set?(attr)
        self.class.fields.has_key?(attr) && self.instance_variable_defined?("@#{attr}")
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
