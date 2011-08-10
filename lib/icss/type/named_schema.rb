module Icss
  module Meta

    #
    # Record, enums and fixed are named schema. Each has a fullname that is
    # composed of two parts; a name and a namespace. Equality of names is
    # defined on the fullname.
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
    module NamedSchema
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
      def typename
        @typename  ||= fullname.to_s.gsub(/.*[\.]/, "")
      end
      def namespace
        @namespace ||= fullname.to_s.gsub(/\.[^\.]+\z/so, "")
      end
      #
      def to_schema
        # p [:to_schema, self, __FILE__]
        (defined?(super) ? super() : {}).merge(
          :name      => typename,
          :namespace => namespace,
          :doc       => doc,
          )
      end

      def inscribe_schema(schema_obj, klass)
        klass.class_eval{ define_method(:_schema){ schema_obj } }
        field_names.each do |attr|
          val = schema_obj.send(attr)
          klass.class_eval{ define_method(attr){ val } }
        end
      end

      def get_metatype
        metatype_module = Icss::Meta::NamedSchema.get_meta_module(self.to_s)
        self.class_eval{ include(metatype_module) }
        metatype_module
      end

      #
      # for type science.astronomy.ufo_sighting, we synthesize
      # * a module, ::Icss::Meta::Science::Astronomy::UfoSightingType
      # * a class,  ::Icss::Science::Astronomy::UfoSighting
      #
      # If no superklass is given, Icss::Entity is used.
      def self.make(fullname, superklass)
        meta_module = get_meta_module(fullname)
        klass       = get_type_klass( fullname, superklass)
        klass.class_eval{ include(meta_module) }
        [klass, meta_module]
      end

      #
      # Manufacture of klass and meta_module
      #

      # Returns the klass for the given scope and name, starting with '::Icss'
      # and creating all necessary parents along the way. Note that if the given
      # class or its parent scopes already exist, they're trusted to be correct
      # -- we don't do any error checking as to their type or superclass.
      #
      # @example
      #   Icss::Meta::NamedSchema.get_type_klass('this.that.the_other')
      #   # Icss::This::That::TheOther
      #
      # @param scope_names [Array of String]
      # @param superklass  [Class] - the superclass to use if the class doesn't exist.
      def self.get_type_klass(fullname, superklass)
        fullname = Icss::Meta::Type.fullname_for(fullname)
        return Class.new(superklass) if fullname.nil?
        #
        scope_names   = scope_names_for(fullname)
        klass_name    = scope_names.pop
        parent_module = get_nested_module(%w[Icss] + scope_names)
        #
        if parent_module.const_defined?(klass_name)
          parent_module.const_get(klass_name)
        else
          parent_module.const_set(klass_name, Class.new(superklass))
        end
      end

    protected

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
          if parent_module.const_defined?(module_name)
            parent_module.const_get(module_name)
          else
            parent_module.const_set(module_name.to_sym, Module.new)
          end
        end
      end

      # Returns the meta-module for the given scope and name, starting with
      # '::Icss::Meta' and creating all necessary parents along the way.
      # @example
      #   Icss::Meta::TypeFactory.get_meta_module(["This", "That"], "TheOther")
      #   # Icss::Meta::This::That::TheOtherType
      def self.get_meta_module(fullname)
        fullname = Icss::Meta::Type.fullname_for(fullname)
        return Module.new if fullname.nil?
        #
        scope_names      = scope_names_for(fullname)
        meta_module_name = scope_names.pop + "Type"
        get_nested_module(%w[Icss Meta] + scope_names + [meta_module_name])
      end


    end
  end
end
