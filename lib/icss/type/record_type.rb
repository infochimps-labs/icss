module Icss
  module Meta
    module RecordType

      module Schema
        include Icss::Meta::HasFields
        include Icss::Meta::NamedSchema
      end
      def self.included(base) base.extend(Icss::Meta::RecordType::Schema) ; end

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

    module ErrorType
      module Schema
        include Icss::Meta::HasFields
        include Icss::Meta::NamedSchema
        include Icss::Meta::RecordType::Schema

        class Writer < ::Icss::Meta::NamedSchema::Writer
        end

      end
      def self.included(base) base.extend(Icss::Meta::ErrorType::Schema) ; end
    end

  end
end
