module Icss
  module Meta


    #
    # Defines the schema methods:
    # * metatype:  a module holding the methods we synthesize for you
    #
    # * self.make: generates a class with the given name and superclass,
    #   with metatype attached.
    #
    # * Metatype module provides behavior to the instance
    #
    # * Schema module provides behavior to the class.
    #
    # Consider the Restaurant.
    #
    # * It includes RecordType
    #
    #   You typically *extend* WhateverSchema on FooType (so that its /class/
    #   accepts schema Whatever-shaped schema). *include* Schema in FooSchema
    #   (so that it also is_a Schema), and
    #
    module Schema

      #
      # Returns the metatype -- a module extending the type, on which all the
      # accessors and receive methods are inscribed. (This allows you to call
      # +super()+ from within receive_foo)
      #
      def metatype
        return @metatype if @metatype
        @metatype = Icss::Meta::Schema.get_meta_module(self.to_s)
        self.class_eval{ include(@metatype) }
        @metatype
      end

      # ---------------------------------------------------------------------------
      #
      # Schema Factory methods
      #

      #
      # Manufactures klass and metatype
      #
      # for type science.astronomy.ufo_sighting, we synthesize
      # * a module, ::Icss::Meta::Science::Astronomy::UfoSightingType
      # * a class,  ::Icss::Science::Astronomy::UfoSighting
      #
      # If no superklass is given, Icss::Entity is used.
      def self.make(fullname, superklass)
        klass    = get_type_klass(fullname, superklass)
        metatype = get_meta_module(klass.to_s)
        klass.class_eval{ include(metatype) }
        [klass, metatype]
      end

      def self.inscribe_schema(schema_obj, type_schema)
        type_schema.class_eval{ define_method(:_schema){ schema_obj } }
        field_names.each do |attr|
          val = schema_obj.send(attr)
          type_schema.class_eval{ define_method(attr){ val } }
        end
      end

    protected

      def define_metatype_method(meth_name, visibility=:public, &blk)
        metatype.class_eval do
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
      #   Icss::Meta::Schema.get_type_klass('this.that.the_other')
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
        scope_names[-1] += "Type"
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
          if parent_module.const_defined?(module_name)
            parent_module.const_get(module_name)
          else
            parent_module.const_set(module_name.to_sym, Module.new)
          end
        end
      end

    end
  end
end
