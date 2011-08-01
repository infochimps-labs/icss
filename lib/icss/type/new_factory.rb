module Icss
  module Meta
    module TypeFactory
      module_function
      def make(fullname)
        klass_for(fullname)
      end

      def ruby_klass_scope_names(fullname)
        fullname.split('.').map(&:camelize)
      end
      def ruby_klass_name(fullname)
        "::" + ruby_klass_scope_names(fullname).join('::')
      end
      def ruby_klass_parent(fullname)
        ("::" + ruby_klass_scope_names(fullname)[0..-2].join('::')).constantize
      end

      def ensure_parent_modules!(fullname)
        ruby_klass_scope_names(fullname)[0..-2].inject(Object) do |parent_module, module_name|
          new_parent   = "::#{parent_module}::#{module_name}".constantize rescue nil
          new_parent ||= parent_module.const_set(module_name.to_sym, Module.new)
          # p [parent_module, new_parent, module_name]
          new_parent
        end
      end

      def klass_for(fullname)
        ensure_parent_modules!(fullname)
        parent_module = ruby_klass_parent(fullname)
        klass_basename = ruby_klass_scope_names(fullname).last.to_sym
        klass   = parent_module.const_get(klass_basename) rescue nil
        klass ||= parent_module.const_set(klass_basename, Class.new(::Icss::Meta::BaseType))
        # decorate_with_receivers(klass)
        # decorate_with_conveniences(klass)
        # decorate_with_validators(klass)
        klass
      end

      def decorate_with_receivers klass
        fields.each do |field|
          field.define_receiver_on(klass)
        end
      end

      def decorate_with_conveniences klass
        klass.send :include, Receiver::ActsAsHash
        klass.send :include, Receiver::ActiveModelShim
      end

      def decorate_with_validators klass
        fields.each do |field|
          puts field.to_hash
          if field.validates
            puts field.validates
            klass.validates(field.name.to_sym, field.validates)
          end
        end
      end

    end


    class BaseType
      # include Receiver

      class << self
        include Receiver
        rcvr_accessor :name,       String
        rcvr_accessor :doc,        String
        rcvr_accessor :ruby_klass, Object
        rcvr_accessor :validates,  Hash
        rcvr_accessor :namespace,  String
        rcvr_accessor :fields,     Array, :of => Icss::RecordField, :required => true
        rcvr_accessor :is_a,       Array, :of => String, :default => []

        def _receiver_fields
          singleton_class.receiver_attr_names
        end

        def _receiver_defaults
          singleton_class.receiver_defaults
        end

        def _after_receivers
          singleton_class.after_receivers
        end

        # In named types, the namespace and name are determined in one of the following ways:
        #
        # * A name and namespace are both specified. For example, one might use
        #   "name": "X", "namespace": "org.foo" to indicate the fullname org.foo.X.
        #
        # * A fullname is specified. If the name specified contains a dot, then it is
        #   assumed to be a fullname, and any namespace also specified is ignored. For
        #   example, use "name": "org.foo.X" to indicate the fullname org.foo.X.
        #
        # * A name only is specified, i.e., a name that contains no dots. In this case
        #   the namespace is taken from the most tightly enclosing schema or
        #   protocol. For example, if "name": "X" is specified, and this occurs within
        #   a field of the record definition of org.foo.Y, then the fullname is
        #   org.foo.X.
        #
        def name= nm
          if nm.include?('.')
            split_name = nm.split('.')
            @use_fullname = true
            @name      = split_name.pop
            @namespace = split_name.join('.')
          else
            @name = nm
          end
          ::Icss::Type::DERIVED_TYPES[@name.to_sym] = self
          @name
        end

        # If the namespace is given in the name (using a dotted name string) then
        # any namespace also specified is ignored.
        def receive_namespace nmsp
          if @namespace then warn "Warning: namespace already set, ignoring" and return ; end
          @namespace = nmsp
        end
        def namespace
          @namespace || (parent ? parent.namespace : "")
        end

        # If no explicit namespace is specified, the namespace is taken from the
        # most tightly enclosing schema or protocol. For example, if "name": "X" is
        # specified, and this occurs within a field of the record definition of
        # org.foo.Y, then the fullname is org.foo.X.
        #
        def fullname
          [namespace, name].reject(&:blank?).join('.')
        end

        def to_hash
          hsh = super
          if    @use_fullname then hsh[:name] = fullname
          elsif @namespace    then hsh.merge!( :namespace => @namespace ) ; end
          hsh.merge( :type => self.class.type )
        end
      end

    end
  end
end
