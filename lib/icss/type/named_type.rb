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
        self.name.gsub(/^:*Icss::/, '').underscore.gsub(%r{/},".")
      end
      def typename
        @typename  ||= fullname.gsub(/.*[\.]/, "")
      end
      def namespace
        @namespace ||= fullname.gsub(/\.[^\.]+/, "")
      end

      def doc() "" end
      def doc=(str)
        singleton_class.class_eval do
          remove_possible_method(:doc)
          define_method(:doc){ str }
        end
      end
    end
  end
end
