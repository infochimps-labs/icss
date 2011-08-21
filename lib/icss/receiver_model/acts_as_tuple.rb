module Icss
  module ReceiverModel
    module ActsAsTuple

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

      module ClassMethods
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
          fields.each do |field|
            if field[:type].respond_to?(:consume_tuple)
              val = field[:type].consume_tuple(tuple)
            else
              val = tuple.shift
            end
            obj.send("receive_#{field[:name]}", val) if val
          end
          obj.send(:run_after_receivers, {})
          obj
        end
      end
      def self.included(base) base.extend(Icss::ReceiverModel::ActsAsTuple::ClassMethods) ; end

    end
  end

end
