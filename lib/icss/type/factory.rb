module Icss
  class RecordType < NamedType

    # def ruby_klass
    #   klass_name = fullname.to_s.classify+"Type"
    #
    #   @klass ||= Class.new do
    #     fields.each do |field|
    #       instance_eval{ field.define_receiver }
    #     end
    #   end
    # end
    #    klass = Icss::Type.const_set(klass_name, Class.new(Icss::RecordType))
    #    # FIXME: doesn't follow receive pattern
    #    klass.name = hsh[:name].to_s.to_sym if hsh[:name]
    #    klass.doc  = hsh[:doc]              if hsh[:doc]
    #    klass.type = :record
    #    ::Icss::Type::DERIVED_TYPES[hsh[:name].to_sym] = klass
    #  end

  end
end
