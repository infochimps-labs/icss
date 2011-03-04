module Icss
  #
  # Generic ICSS base type
  #
  class Type
    include Receiver
    rcvr :name,   String
    rcvr :type,   Symbol
    rcvr :doc,    String
    #
    class_inheritable_accessor :avro_name, :pig_name

    # Keep the body around. FIXME: want to get rid of this, cops might find the body
    attr_accessor :body
    def after_receive hsh
      self.body = hsh
    end

    def self.receive hsh
      case hsh[:type].to_sym || hsh["type"].to_sym
      when :record then obj = Icss::RecordType.new(hsh["name"])
      else              obj = self.new
      end
      obj.receive!(hsh)
      obj
    end

    def to_hash()
      {:name => name, :type => type, :doc => doc }
    end
    # This will cause funny errors when it is an element of something that's to_json'ed
    def to_json() to_hash.to_json ; end

    # Named types registry
    NAMED_TYPES = {}
    def self.find type_name
      NAMED_TYPES[type_name.to_sym]
    end

    #
    # Schema Translation
    #

    def pig_type
      self.class.pig_name
    end
  end

  class NamedType < Type
    def initialize name
      ::Icss::Type::NAMED_TYPES[name.to_sym] = self
    end
  end

  #
  # Icss/Avro Record type
  #
  # A record type has fields, each of which
  #
  class RecordType < NamedType
    rcvr :fields, Array, :of => Icss::Type

    def to_hash
      super.merge( :fields => fields.map{|field| field.to_hash} )
    end
  end

  class StringType < Type
    self.pig_name  = 'chararray'
    self.avro_name = 'string'
  end
  class IntegerType < Type
    self.pig_name  = 'int'
    self.avro_name = 'int'
  end
  class LongType < Type
    self.pig_name  = 'long'
    self.avro_name = 'long'
  end
  class FloatType < Type
    self.pig_name  = 'float'
    self.avro_name = 'float'
  end
  class DoubleType < Type
    self.pig_name  = 'double'
    self.avro_name = 'double'
  end
  class BytesType < Type
    self.pig_name  = 'bytearray'
    self.avro_name = 'bytes'
  end
  class FixedType < Type
    self.pig_name  = 'bytearray'
    self.avro_name = 'fixed'
  end
end
