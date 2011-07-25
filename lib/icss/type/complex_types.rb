module Icss

  class RecordType < NamedType

    rcvr_accessor :fields, Array, :of => Icss::RecordField, :required => true
    rcvr_accessor :is_a, Array, :of => String, :default => []
    self.type = :record

    after_receive do |hsh|
      is_a.each do |ref|
        addon = ReferencedType.receive(ref)
        fields.push(addon.fields).flatten!
      end
      Icss::Type::DERIVED_TYPES[name.to_sym] = self
    end

    def to_hash
      super.merge( :fields => ( fields || [] ).map{ |field| field.to_hash } )
    end

  end

  class ReferencedType < RecordType

    def self.receive(ref_type)
      split_name = ref_type.to_s.split('.')
      name = split_name.pop
      nmsp = split_name.join('_')
      super(lookup_ref(nmsp, name))
    end

    def self.lookup_ref(nmsp, name)
      ref = YAML.load(File.read(File.join(File.dirname(__FILE__), nmsp) + '.yaml'))
      ref['types'].select{ |t| t['name'] == name }.first
    end

  end

  class ErrorType < RecordType
    self.type = :error
  end

  class EnumType < NamedType

    rcvr_accessor :symbols, Array, :of => String, :required => true
    self.type = :enum

    def to_hash
      super.merge( :symbols => symbols )
    end

  end

  class EnumerableType < Type

    class_attribute :type
    class_attribute :ruby_klass

    def to_hash
      super.merge( :type => type.to_s )
    end

  end

  class ArrayType < EnumerableType

    rcvr_accessor :items, TypeFactory, :required => true
    self.type = :array
    self.ruby_klass = Array

    def title
      "array of #{items.title}"
    end

    def to_hash
      super.merge( :items => (items && items.name) )
    end

  end

  class MapType < EnumerableType

    rcvr_accessor :values, TypeFactory, :required => true
    self.type       = :map
    self.ruby_klass = Hash

    def to_hash
      super.merge( :values => values.to_hash )
    end

  end

  HashType = MapType unless defined?(HashType)

  class UnionType < EnumerableType

    attr_accessor :available_types
    attr_accessor :referenced_types
    self.type = :union

    def receive! type_list
      self.available_types = type_list.map do |type_info|
        type = TypeFactory.receive(type_info)
        (referenced_types||=[]) << type if (type_info.is_a?(String) || type_info.is_a?(Symbol))
        type
      end
    end

    def to_hash
      available_types.map{|t| t.name } #  (referenced_types||=[]).include?(t) ? t.name : t.to_hash }
    end
  end

  class FixedType < NamedType

    rcvr_accessor :size, Integer, :required => true
    class_attribute :ruby_klass
    self.type = :fixed
    self.ruby_klass = String

    def to_hash
      super.merge( :size => size )
    end

  end

end
