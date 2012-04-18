module Icss
  module Meta

    #
    # Record, Error, Enum and Fixed are named types. Each has a fullname that is
    # composed of two parts; a name and a namespace. Equality of names is
    # defined on the fullname.
    #
    # The name portion of a fullname, and record field names, must:
    #
    # * start with [A-Za-z_]
    # * subsequently contain only [A-Za-z0-9_]
    # * A namespace is a dot-separated sequence of such names.
    #
    # References to previously defined names are as in the latter two cases above:
    # if they contain a dot they are a fullname, if they do not contain a dot, the
    # namespace is the namespace of the enclosing definition.
    #
    # Simple type names have no namespace and their names may not be defined in
    # any namespace. A schema may only contain multiple definitions of a
    # fullname if the definitions are equivalent.
    #
    module NamedType
      def doc() "" end
      def doc=(str)
        singleton_class.class_eval do
          remove_possible_method(:doc)
          define_method(:doc){ str }
        end
      end
      #
      def fullname
        ::Icss::Meta::Type.fullname_for(self.name)
      end
      def basename
        @basename  ||= fullname.to_s.gsub(/.*[\.]/, "")
      end
      def namespace
        @namespace ||= fullname.to_s.include?('.') ? fullname.to_s.gsub(/\.[^\.]+\z/so, '') : ''
      end
      def pathname
        fullname.to_s.gsub(/\./, '/')
      end
      #
      def to_schema
        if respond_to?(:_schema) then return _schema.to_hash ; end
        {
          :name      => fullname,
          # :namespace => namespace,
          :doc       => doc,
        }.compact_blank
      end

      def is_core?
        respond_to?(:_schema) && _schema.is_core?
      end

      # ---------------------------------------------------------------------------
      #
      # Type Factory methods
      #

      #
      # Returns the metamodel -- a module extending the type, on which all the
      # accessors and receive methods are inscribed. (This allows you to call
      # +super()+ from within receive_foo)
      #
      def metamodel
        return @metamodel if @metamodel
        @metamodel = Icss::Meta::NamedType.get_meta_module(self.to_s)
        self.class_eval{ include(@metamodel) }
        @metamodel
      end

      #
      # Manufactures klass and metamodel
      #
      # for type science.astronomy.ufo_sighting, we synthesize
      # * a module, ::Icss::Meta::Science::Astronomy::UfoSightingType
      # * a class,  ::Icss::Science::Astronomy::UfoSighting
      #
      # If no superklass is given, Icss::Entity is used.
      def self.make(fullname, superklass)
        klass    = get_model_klass(fullname, superklass)
        metamodel = get_meta_module(klass.to_s)
        klass.class_eval{ extend(::Icss::Meta::NamedType) }
        klass.class_eval{ include(metamodel) }
        [klass, metamodel]
      end

    protected

      def define_metamodel_method(meth_name, visibility=:public, &blk)
        metamodel.class_eval do
          define_method(meth_name, &blk) unless method_defined?(meth_name)
          case visibility
          when :protected then protected meth_name
          when :private   then private   meth_name
          when :public    then public    meth_name
          else raise ArgumentError, "visibility must be :public, :private or :protected"
          end
        end
      end

      # Returns the klass for the given scope and name, starting with '::Icss'
      # and creating all necessary parents along the way. Note that if the given
      # class or its parent scopes already exist, they're trusted to be correct
      # -- we don't do any error checking as to their type or superclass.
      #
      # @example
      #   Icss::Meta::Type.get_model_klass('this.that.the_other')
      #   # Icss::This::That::TheOther
      #
      # @param scope_names [Array of String]
      # @param superklass  [Class] - the superclass to use if the class doesn't exist.
      def self.get_model_klass(fn, superklass)
        fullname = Icss::Meta::Type.fullname_for(fn)
        return Class.new(superklass) if fullname.nil?
        #
        scope_names   = scope_names_for(fullname)
        klass_name    = scope_names.pop
        parent_module = get_nested_module(%w[Icss] + scope_names)

        # const_defined?(klass, inherit), const_get(klass, inherit)
        # inherit = false makes these methods be scoped to parent_module instead of universally
        if parent_module.const_defined?(klass_name, false)
          klass = parent_module.const_get(klass_name, false)
          # #{superklass.object_id}: #{klass.ancestors.map{|o| [o, o.object_id] }}
          unless klass.ancestors.include?(superklass)
            warn "+++++++++++++++++++++++++++++++ Superclass and is_a? mismatch for #{klass.inspect} (doesn't inherit from #{superklass.inspect})"
            # p [klass_name, klass, Icss::Thing.object_id, ::Icss::Thing.object_id, Icss.const_get(:Thing).object_id,]
            # p klass      .ancestors.flatten.map{|t| [t, t.object_id]}
            # p Icss::Thing.ancestors.flatten.map{|t| [t, t.object_id]}
          end
          klass
        else
          parent_module.const_set(klass_name, Class.new(superklass))
        end
      end

      # Returns the meta-module for the given scope and name, starting with
      # '::Icss::Meta' and creating all necessary parents along the way.
      #
      # @example
      #   Icss::Meta::TypeFactory.get_meta_module(["This", "That"], "TheOther")
      #   # Icss::Meta::This::That::TheOtherModel
      def self.get_meta_module(fullname)
        fullname = Icss::Meta::Type.fullname_for(fullname)
        return Module.new if fullname.nil?
        #
        scope_names      = scope_names_for(fullname)
        scope_names[-1] += "Model"
        get_nested_module(%w[Icss Meta] + scope_names)
      end

      # Turns a dotted namespace.name into camelized rubylike names for a class
      # @example
      #   scope_names_for('this.that.the_other')
      #   # ["This", "That", "TheOther"]
      def self.scope_names_for(fullname)
        fullname.split('.').map(&:camelize)
      end

      # Returns a module for the given scope names, rooted always at Object (so
      # implicity with '::').
      # @example
      #   get_nested_module(["This", "That", "TheOther"])
      #   # This::That::TheOther
      def self.get_nested_module(scope_names)
        scope_names.inject(Object) do |parent_module, module_name|

          # const_defined?(klass, inherit), const_get(klass, inherit)
          # inherit = false makes these methods be scoped to parent_module instead of universally
          if parent_module.const_defined?(module_name, false)
            parent_module.const_get(module_name, false)
          else
            parent_module.const_set(module_name.to_sym, Module.new)
          end
        end
      end

    end

  end
end
