module Icss
  module Type
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
        NamedType.fullname_for(self.name)
      end
      def typename
        @typename  ||= fullname.gsub(/.*[\.]/, "")
      end
      def namespace
        @namespace ||= fullname.gsub(/\.[^\.]+/, "")
      end

      def self.fullname_for(klass_name)
        klass_name.to_s.gsub(/^:*Icss::/, '').underscore.gsub(%r{/},".")
      end
      def self.klassname_for(fullname)
        nm = fullname.to_s.
          gsub(%r{::},'.').gsub(/^:*icss[\.:]+/i, '').
          split('.').map(&:camelize).join('::')
        "::Icss::#{nm}"
      end

       def doc() "" end
      def doc=(str)
        singleton_class.class_eval do
          remove_possible_method(:doc)
          define_method(:doc){ str }
        end
      end

      def schema_hash
        (defined?(super) ? super : {}).merge(
          :name      => typename,
          :namespace => namespace,
          :doc       => doc,
          ).reject{ |k,v| v.nil? }
      end

      #
      # for type science.astronomy.nuforc.ufo_sighting, we synthesize
      # * a module, ::Icss::Meta::Science::Astronomy::Nuforc::UfoSightingType
      # * a class,  ::Icss::Science::Astronomy::Nuforc::UfoSighting
      #
      # If no superklass is given, Icss::Entity is used.
      def self.make(fullname, superklass=nil)
        superklass   ||= Icss::Entity
        scope_names    = scope_names_for(fullname)
        klass_name     = scope_names.pop
        meta_module    = get_meta_module(scope_names, klass_name)
        klass          = get_type_klass( scope_names, klass_name, superklass)
        klass.class_eval{ include meta_module }
        [klass, meta_module]
      end

    protected

      #
      # Manufacture of klass and meta_module
      #

      # Turns a dotted namespace.name into camelized rubylike names for a class
      # @example
      #   scope_names_for('this.that.the_other')
      #   # ["This", "That", "TheOther"]
      def self.scope_names_for(fullname)
        fullname.split('.').map(&:camelize)
      end

      # Returns the meta-module for the given scope and name, starting with
      # '::Icss::Meta' and creating all necessary parents along the way.
      # @example
      #   Icss::Meta::TypeFactory.get_meta_module(["This", "That"], "TheOther")
      #   # Icss::Meta::This::That::TheOtherType
      def self.get_meta_module(scope_names, klass_name)
        meta_module_name = "#{klass_name}Type"
        get_module_scope(%w[Icss Meta] + scope_names + [meta_module_name])
      end

      # Returns the klass for the given scope and name, starting with '::Icss'
      # and creating all necessary parents along the way. Note that if the given
      # class or its parent scopes already exist, they're trusted to be correct
      # -- we don't do any error checking as to their type or superclass.
      #
      # @example
      #   Icss::Meta::TypeFactory.get_klass(["This", "That"], "TheOther")
      #   # Icss::This::That::TheOther
      #
      # @param scope_names [Array of String]
      # @param superklass  [Class] - the superclass to use if the class doesn't exist.
      def self.get_type_klass(scope_names, klass_name, superklass)
        parent_module = get_module_scope(%w[Icss] + scope_names)
        if parent_module.const_defined?(klass_name)
          klass = parent_module.const_get(klass_name)
        else
          klass = parent_module.const_set(klass_name, Class.new(superklass))
        end
        klass
      end

      # Returns a module for the given scope names, rooted always at Object (so
      # implicity with '::').
      # @example
      #   get_module_scope(["This", "That", "TheOther"])
      #   # This::That::TheOther
      def self.get_module_scope(scope_names)
        scope_names.inject(Object) do |parent_module, module_name|
          if parent_module.const_defined?(module_name)
            new_parent = parent_module.const_get(module_name)
          else
            new_parent = parent_module.const_set(module_name.to_sym, Module.new)
          end
          new_parent
        end
      end

    end
  end
end
