module Icss
  module Meta

    #
    # Describes an Avro Union type.
    #
    # Unions are represented using JSON arrays. For example, ["string", "null"]
    # declares a schema which may be either a string or null.
    #
    # Unions may not contain more than one schema with the same type, except for
    # the named types record, fixed and enum. For example, unions containing two
    # array types or two map types are not permitted, but two types with different
    # names are permitted. (Names permit efficient resolution when reading and
    # writing unions.)
    #
    # Unions may not immediately contain other unions.
    #
    class UnionSchema
      #   extend Icss::Meta::ContainerType
      #   #
      #   attr_accessor :embedded_types
      #   attr_accessor :declaration_flavors
      #   #
      #   def receive! type_list
      #     self.declaration_flavors = []
      #     self.embedded_types = type_list.map do |schema|
      #       type = TypeFactory.receive(schema)
      #       declaration_flavors << TypeFactory.classify_schema_declaration(schema)
      #       type
      #     end
      #   end
      #   def to_schema
      #     embedded_types.zip(declaration_flavors).map do |t,fl|
      #       [:structured_schema].include?(fl) ? t.name : t.to_schema
      #     end
      #   end
      # end

    end
  end
end
