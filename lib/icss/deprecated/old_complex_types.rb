module Icss

  #
  # Icss/Avro Record type
  #
  # Records use the type name "record" and support these attributes:
  #
  # * name:      a string providing the name of the record (required).
  # * namespace: a string that qualifies the name;
  # * doc:       a string providing documentation to the user of this schema (optional).
  # * fields:    an array of RecordField's (required).
  #
  # For example, a linked-list of 64-bit values may be defined with:
  #
  #         {
  #           "type": "record",
  #           "name": "LongList",
  #           "fields" : [
  #             {"name": "value", "type": "long"},             // each element has a long
  #             {"name": "next", "type": ["LongList", "null"]} // optional next element
  #           ]
  #         }
  #
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

end
