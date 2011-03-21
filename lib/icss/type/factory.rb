module Icss
  class MetaType
    include Receiver

    def initialize *args
      receive! *args unless args.empty?
    end

    # Returns a string containing an XML representation of its receiver:
    #
    #   {"foo" => 1, "bar" => 2}.to_xml
    #   # =>
    #   # <?xml version="1.0" encoding="UTF-8"?>
    #   # <hash>
    #   #   <foo type="integer">1</foo>
    #   #   <bar type="integer">2</bar>
    #   # </hash>
    #
    # To do so, the method loops over the pairs and builds nodes that depend on
    # the _values_. Given a pair +key+, +value+:
    #
    # * If +value+ is a hash there's a recursive call with +key+ as <tt>:root</tt>.
    #
    # * If +value+ is an array there's a recursive call with +key+ as <tt>:root</tt>,
    #   and +key+ singularized as <tt>:children</tt>.
    #
    # * If +value+ is a callable object it must expect one or two arguments. Depending
    #   on the arity, the callable is invoked with the +options+ hash as first argument
    #   with +key+ as <tt>:root</tt>, and +key+ singularized as second argument. Its
    #   return value becomes a new node.
    #
    # * If +value+ responds to +to_xml+ the method is invoked with +key+ as <tt>:root</tt>.
    #
    # * Otherwise, a node with +key+ as tag is created with a string representation of
    #   +value+ as text node. If +value+ is +nil+ an attribute "nil" set to "true" is added.
    #   Unless the option <tt>:skip_types</tt> exists and is true, an attribute "type" is
    #   added as well according to the following mapping:
    #
    #     XML_TYPE_NAMES = {
    #       "Symbol"     => "symbol",
    #       "Fixnum"     => "integer",
    #       "Bignum"     => "integer",
    #       "BigDecimal" => "decimal",
    #       "Float"      => "float",
    #       "TrueClass"  => "boolean",
    #       "FalseClass" => "boolean",
    #       "Date"       => "date",
    #       "DateTime"   => "datetime",
    #       "Time"       => "datetime"
    #     }
    #
    # By default the root node is "hash", but that's configurable via the <tt>:root</tt> option.
    #
    # The default XML builder is a fresh instance of <tt>Builder::XmlMarkup</tt>. You can
    # configure your own builder with the <tt>:builder</tt> option. The method also accepts
    # options like <tt>:dasherize</tt> and friends, they are forwarded to the builder.
    # Returns a string containing an XML representation of its receiver:
    #
    #   {"foo" => 1, "bar" => 2}.to_xml
    #   # =>
    #   # <?xml version="1.0" encoding="UTF-8"?>
    #   # <hash>
    #   #   <foo type="integer">1</foo>
    #   #   <bar type="integer">2</bar>
    #   # </hash>
    #
    # To do so, the method loops over the pairs and builds nodes that depend on
    # the _values_. Given a pair +key+, +value+:
    #
    # * If +value+ is a hash there's a recursive call with +key+ as <tt>:root</tt>.
    #
    # * If +value+ is an array there's a recursive call with +key+ as <tt>:root</tt>,
    #   and +key+ singularized as <tt>:children</tt>.
    #
    # * If +value+ is a callable object it must expect one or two arguments. Depending
    #   on the arity, the callable is invoked with the +options+ hash as first argument
    #   with +key+ as <tt>:root</tt>, and +key+ singularized as second argument. Its
    #   return value becomes a new node.
    #
    # * If +value+ responds to +to_xml+ the method is invoked with +key+ as <tt>:root</tt>.
    #
    # * Otherwise, a node with +key+ as tag is created with a string representation of
    #   +value+ as text node. If +value+ is +nil+ an attribute "nil" set to "true" is added.
    #   Unless the option <tt>:skip_types</tt> exists and is true, an attribute "type" is
    #   added as well according to the following mapping:
    #
    #     XML_TYPE_NAMES = {
    #       "Symbol"     => "symbol",
    #       "Fixnum"     => "integer",
    #       "Bignum"     => "integer",
    #       "BigDecimal" => "decimal",
    #       "Float"      => "float",
    #       "TrueClass"  => "boolean",
    #       "FalseClass" => "boolean",
    #       "Date"       => "date",
    #       "DateTime"   => "datetime",
    #       "Time"       => "datetime"
    #     }
    #
    # By default the root node is "hash", but that's configurable via the <tt>:root</tt> option.
    #
    # The default XML builder is a fresh instance of <tt>Builder::XmlMarkup</tt>. You can
    # configure your own builder with the <tt>:builder</tt> option. The method also accepts
    # options like <tt>:dasherize</tt> and friends, they are forwarded to the
    #builder.
    #
    def to_xml options={}, &block
      options = options.reverse_merge(:root => self.class.xml_type_name)
      xml_hsh = self.to_hash
      xml_hsh.merge!(:_note => "XML support is experimental, structure may change in future") unless options[:skip_instruct]
      xml_hsh.to_xml(options, &block)
    end

    def self.xml_type_name
      self.to_s.demodulize.underscore.dasherize
    end

    def to_json *args
      to_hash.to_json(*args)
    end
  end

  class RecordType < NamedType

    def ruby_klass_scope_names
      fullname.split('.').map(&:camelize)
    end
    def ruby_klass_name
      "::" + ruby_klass_scope_names.join('::')
    end
    def ruby_klass_parent
      ("::" + ruby_klass_scope_names[0..-2].join('::')).constantize
    end

    def ensure_parent_modules!
      ruby_klass_scope_names[0..-2].inject(Object) do |parent_module, module_name|
        new_parent   = "::#{parent_module}::#{module_name}".constantize rescue nil
        new_parent ||= parent_module.const_set(module_name.to_sym, Module.new)
        # p [parent_module, new_parent, module_name]
        new_parent
      end
    end

    def define_klass
      ensure_parent_modules!
      parent_module = ruby_klass_parent
      klass_basename = ruby_klass_scope_names.last.to_sym
      klass   = parent_module.const_get(klass_basename) rescue nil
      klass ||= parent_module.const_set(klass_basename, Class.new(::Icss::MetaType))
      klass
    end

    def ruby_klass
      return @klass if @klass
      klass = define_klass
      decorate_with_receivers(klass)
      decorate_with_conveniences(klass)
      @klass = klass
    end

    def decorate_with_receivers klass
      fields.each do |field|
        field.define_receiver_on(klass)
      end
    end

    def decorate_with_conveniences klass
      klass.send :include, Receiver::ActsAsHash
    end

  end

  Icss::RecordField.class_eval do
    def define_receiver_on(klass)
      if union? || enum?
        warn "Can't handle union or enum types yet: #{self.inspect}"
        return
      end
      klass.rcvr_accessor name.to_sym, type.ruby_klass, field_receiver_attrs
    end

    def field_receiver_attrs
      attrs = {}
      (self.class.receiver_attr_names - [:name, :type]).each do |attr|
        attrs[attr] = self.send(attr)
      end
      attrs
    end
  end
end
