module Icss
    # An avro name must
    # * start with [A-Za-z_]
    # * subsequently contain only [A-Za-z0-9_]
    # def validate_name
    #   (name =~ /\A[A-Za-z_]\w*\z/) or raise "An avro name must start with [A-Za-z_] and contain only [A-Za-z0-9_]; have #{name}. A namespace is the dot-separated sequence of such names."
    # end
    #
    # def validate_namespace
    #   (name =~ /\A([A-Za-z_]\w*\.?)+\z/) or raise "An avro name must start with [A-Za-z_] and contain only [A-Za-z0-9_]; have #{name}. A namespace is the dot-separated sequence of such names."
    # end
end
