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
        #   # => ['fullname', 'street_address.housenum', 'street_address.street']
        #
        # @param [Integer] max_key_segments the maximum length of key (depth to
        #   recurse); a stark 3 by default.
        def tuple_keys(max_key_segments=3)
          tuple_fields(max_key_segments).map{|field_set| field_set.map(&:name).join('.') }
        end

        # returns a depth-first traversal of the object's fields, as RecordFields:
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
        #   # => [ [<RecordField name='fullname' ...>],
        #   #      [<RecordField name='street_address' ...>, <RecordField name='housenum' ...>],
        #   #      [<RecordField name='street_address' ...>, <RecordField name='street' ...>],
        #
        # Note that RecordField helpfully supplies a 'parent' attribute pointing to it parent record.
        #
        # @param [Integer] max_key_segments the maximum length of key (depth to
        #   recurse); a stark 3 by default.
        #
        def tuple_fields(max_key_segments=3)
          # return @tuple_fields if @tuple_fields
          @tuple_fields = field_schemas.flat_map do |fn, fld|
            if (max_key_segments > 1) && fld[:type].respond_to?(:tuple_fields)
              fld[:type].tuple_fields(max_key_segments-1).map{|subfield| [fld, subfield].flatten }
            else
              [[fld]]
            end
          end
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
