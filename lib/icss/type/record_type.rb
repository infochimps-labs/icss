require 'icss/type/extended_primitive_types'
require 'icss/type/record_type_class_methods'
require 'icss/type/field_receivers'

module Icss

  class Entity
  end

  module Meta

    #
    # Record, enums and fixed are named types. Each has a fullname that is
    # composed of two parts; a name and a namespace. Equality of names is defined
    # on the fullname.
    #
    # The name portion of a fullname, and record field names must:
    # * start with [A-Za-z_]
    # * subsequently contain only [A-Za-z0-9_]
    # * A namespace is a dot-separated sequence of such names.
    #
    # References to previously defined names are as in the latter two cases above:
    # if they contain a dot they are a fullname, if they do not contain a dot, the
    # namespace is the namespace of the enclosing definition.
    #
    # Primitive type names have no namespace and their names may not be defined in
    # any namespace. A schema may only contain multiple definitions of a fullname
    # if the definitions are equivalent.
    #
    module NamedType
      def fullname
        self.name.underscore.gsub(%r{/},".")
      end
      def typename
        @typename  ||= fullname.gsub(/.*[\.]/, "")
      end
      def namespace
        @namespace ||= fullname.gsub(/\.[^\.]+/, "")
      end

      def doc() "" end
      def doc=(str)
        p [self, singleton_class]
        singleton_class.class_eval do
          remove_possible_method(:doc)
          define_method(:doc){ str }
        end
      end
    end

    module RecordType
      def self.included(base)
        base.extend(Icss::Meta::NamedType)
        base.extend(FieldDecorators)
        base.extend(ReceiverDecorators)
      end
    end



      module FieldDecorators

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
        # @option info [String] :doc -- description of field for users (optional)
        #
        # @option info [Object] :default -- a default value for this field, used
        #   when reading instances that lack this field (optional).
        #   Permitted values depend on the field's schema type, according to the
        #   table below. Default values for union fields correspond to the first
        #   schema in the union. Default values for bytes and fixed fields are
        #   JSON strings, where Unicode code points 0-255 are mapped to unsigned
        #   8-bit byte values 0-255.
        #
        # @option info [String] :order -- specifies how this field impacts sort
        #   ordering of this record (optional).
        #   Valid values are "ascending" (the default), "descending", or
        #   "ignore". For more details on how this is used, see the the sort
        #   order section below.
        #
        # @option info [Boolean] :required -- same as :validates => :presence
        #
        # @option info [Symbol] :accessor -- with +:none+, no accessor is
        #   created. With +:protected+, +:private+, or +:public+, applies
        #   corresponding access rule.
        #
        # @option info [Symbol] :reader -- with +:none+, no reader is
        #   created. With +:protected+, +:private+, or +:public+, applies
        #   corresponding access rule.
        #
        # @option info [Symbol] :writer -- with +:none+, no writer is
        #   created. With +:protected+, +:private+, or +:public+, applies
        #   corresponding access rule.
        #
        # @option info [Hash] :validates -- sends the validation on to
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
        def field(name, type, info={})
          name = name.to_sym
          add_field_info(name, type, info)
          add_field_accessor(name, info)
          add_receiver(name, type, info)
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

      protected
        def add_field_info(name, type, info)
          @field_names ||= [] ; @fields ||= {}
          @field_names << name unless respond_to?(:field_names) && field_names.include?(name)
          @fields[name] = info.merge({ :name => name, :type => type })
        end

        def add_field_accessor(name, info)
          reader_info = info[:reader] || info[:accessor]
          writer_info = info[:writer] || info[:accessor]
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
      end # ClassMethods

    # #
    # # Avro Schema Declaration
    # #
    # # A Schema is represented in JSON by one of:
    # #
    # # * A JSON string, naming a defined type.
    # # * A JSON object, of the form:
    # #       {"type": "typeName" ...attributes...}
    # #   where typeName is either a primitive or derived type name, as defined
    # #   in the Icss::Type class
    # # * A JSON array, representing a union of embedded types.
    # #
    # #
    # class TypeFactory
    #
    #   def self.receive type_info
    #     case
    #     when type_info.is_a?(Icss::Type)
    #       type_info
    #     when type_info.is_a?(String) || type_info.is_a?(Symbol)
    #       Icss::Type.find(type_info)
    #     when type_info.is_a?(Array)
    #       UnionType.receive(type_info)
    #     else
    #       type_info = type_info.symbolize_keys
    #       raise "No type was given in #{type_info.inspect}" if type_info[:type].blank?
    #       type_name = type_info[:type].to_sym
    #       type = Icss::Type.find(type_name)
    #       obj = type.receive(type_info)
    #     end
    #   end
    #
    # end
  end
end
