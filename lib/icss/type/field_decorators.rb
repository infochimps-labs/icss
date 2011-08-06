module Icss
  module Meta

    module RecordType
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
        def field(name, type, field_info={})
          name = name.to_sym
          add_field_info(name, type, field_info)
          add_field_accessor(name, field_info)
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

        def to_schema
          (defined?(super) ? super : {}).merge(
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

      protected
        def add_field_info(name, type, field_info)
          @field_names ||= [] ; @fields ||= {}
          @field_names << name unless respond_to?(:field_names) && field_names.include?(name)
          @fields[name] = field_info.merge({ :name => name, :type => type })
        end

        def add_field_accessor(name, field_info)
          reader_info = field_info[:reader] || field_info[:accessor]
          writer_info = field_info[:writer] || field_info[:accessor]
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
      end # FieldDecorators
    end
  end
end
