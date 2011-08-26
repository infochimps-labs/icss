module Icss
  module Meta

    # Receives any object just as given.
    #
    # @example
    #   # receive_foo accepts the item just as given
    #   field :foo, Icss::Meta::IdenticalFactory
    #
    class IdenticalFactory
      def self.receive(obj)
        obj
      end
    end

    class IdenticalHashFactory
      def self.to_schema() { :type => 'map' } ; end
      def self.receive(obj)
        unless obj.nil? || obj.respond_to?(:each_pair) then raise(ArgumentError, "Must supply a hashlike value, got #{obj.to_s[0..100]}") ; end
        obj
      end
    end

    class IdenticalArrayFactory
      def self.to_schema() { :type => 'array' } ; end
      def self.receive(obj)
        unless obj.nil? || obj.respond_to?(:each) then raise(ArgumentError, "Must supply an arraylike value, got #{obj.to_s[0..100]}") ; end
        obj
      end
    end

    module TypeFactory

      ::Icss::FACTORY_TYPES.merge!({
          Icss::Meta::TypeFactory       => Icss::Meta::TypeFactory,
          Object                        => Icss::Meta::IdenticalFactory,
          Icss::Meta::IdenticalFactory  => Icss::Meta::IdenticalFactory,
        })

      #
      # A Schema is represented by one of:
      #
      # * A symbol or string, naming a defined type.
      # * A class that responds to +.receive+, returned as itself
      # * A hash (respond_to?(:each_pair), of the form:
      #       {"type": "typename" ...attributes...}
      #   where typename is either a simple or derived type name, as defined
      #   in the Icss::Type class
      # * An array, representing a union of embedded types.
      #
      def self.receive schema
        flavor, klass = classify_schema_declaration(schema)
        # p ['tfr', __FILE__, flavor, klass, schema]
        case flavor
        when :simple            then return klass
        when :factory           then return klass
        when :is_type           then return klass
        when :structured_schema then return receive_structured_schema(klass, schema)
        when :union_schema      then return receive_union_schema(klass, schema)
        when :named_type        then return receive_named_type(klass, schema)
        else
        end
      end

      #
      # A Schema is represented by one of:
      #
      # * A symbol or string, naming a defined type.
      # * A class that responds to +.receive+, returned as itself
      # * A hash (respond_to?(:each_pair), of the form:
      #       {"type": "typeName" ...attributes...}
      #   where typeName is either a simple or derived type name, as defined
      #   in the Icss::Type class
      # * An array, representing a union of embedded types.
      #
      #
      def self.classify_schema_declaration(schema)
        if schema.respond_to?(:each_pair)
          schema.symbolize_keys!
          type = schema[:type]
        else type = schema
        end
        type = type.to_sym if type.respond_to?(:to_sym)
        # p ['clfy', __FILE__, schema, type]

        # FIXME -- make this match the preamble comment

        if    type.is_a?(Module) && type < NamedType          then return [:is_type,           type]
        elsif ::Icss::SIMPLE_TYPES.include?(type)             then return [:simple,            SIMPLE_TYPES[type]]
        elsif (type == Array) && schema[:items].blank?        then return [:factory,           IdenticalArrayFactory]
        elsif (type == Hash)  && schema[:values].blank?       then return [:factory,           IdenticalHashFactory]
        elsif ::Icss::FACTORY_TYPES.include?(type)            then return [:factory,           FACTORY_TYPES[type]]
        elsif ::Icss::STRUCTURED_SCHEMAS.include?(type)       then return [:structured_schema, STRUCTURED_SCHEMAS[type]]
        elsif (type == :base)                                 then return [:is_type,           schema[:name].camelize.constantize]
        elsif (type == :union) || type.is_a?(Array)           then return [:union_schema,      Icss::Meta::UnionSchema]
        elsif type.is_a?(Symbol) && type.to_s =~ /^[\w\.\:]+/ then return [:named_type,        type]
        elsif type.is_a?(Class) || type.is_a?(Module)         then return [:is_type,           type]
        elsif type.respond_to?(:each_pair)                    then return [:is_type,           receive(type)]
        else  raise ArgumentError, %Q{Can not classify #{schema.inspect}: should be the handle for a named type; one of #{SIMPLE_TYPES.keys.join(',')}; a schema of the form {"type": "typename" ...attributes....}; or an array (representing a union type).}
        end
      end

      def self.with_namespace(def_ns)
        old_def_ns = @default_namespace
        @default_namespace = def_ns
        ret = yield
        @default_namespace = old_def_ns
        ret
      end

      def self.namespaced_name(nm)
        nm = nm.to_s
        return nm if (nm == 'thing') || (nm =~ /[\.\/]/)
        [@default_namespace, nm].compact.join('.')
      end

    protected

      def self.receive_named_type(type_name, schema)
        ns_name   = namespaced_name(type_name)
        klass_name = Icss::Meta::Type.klassname_for(ns_name.to_sym)
        # p ['rnt', type_name, schema, ns_name, klass_name]
        begin
          klass_name.constantize
        rescue NameError => e
          # Log.debug "auto loading core type #{ns_name} - #{schema}" if defined?(Log)
          Icss::Meta::Protocol.load_from_catalog("core/#{ns_name}")
          klass_name.constantize
        end
      end

      def self.receive_structured_schema(schema_writer, schema)
        if (schema[:name].to_s !~ /[\.\/]/) && @default_namespace && (schema[:name].to_s != 'thing')
          schema[:namespace] ||= @default_namespace
        end
        schema_writer.receive(schema)
      end

      def self.receive_union_schema(schema_writer, schema)
        schema_writer.receive(schema)
      end

    end
  end
end
