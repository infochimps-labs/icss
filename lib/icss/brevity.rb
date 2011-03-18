#
# Doing
#
#     require 'icss/brevity'
#
# makes the #inspect method on Icss::Type's be nice and readable,
# not GIGANTE PIQUANTE OY CABRON
#
#
module Icss

  Protocol.class_eval do
    def inspect
      ["#<#{self.class.name}",
        inspect_hsh.map{|k,v| "#{k}=#{v}" },
        ">"
      ].join(" ")
    end

    def inspect_hsh
      {
        :name        => name,
        :namespace   => @namespace,
        :types       => (types||[]).map(&:name).inspect,
        :messages    => (messages||{}).values.map(&:name).inspect,
        :data_assets => (data_assets||[]).map(&:name).inspect,
        :doc         => "'#{(doc||"")[0..30].gsub(/[\n\t\r]+/,' ')}...'",
      }
    end
  end

  Message.class_eval do
    def inspect
      ["#<#{self.class.name}",
        inspect_hsh.map{|k,v| "#{k}=#{v}" },
        ">"
      ].join(" ")
    end

    private
    # stuff a compact cartoon of the fields in there
    def inspect_hsh
      {
        :name        => name,
        :request     => summary_of_request_attr, # (request||[]).map(&:type).map(&:name),
        :response    => summary_of_response_attr,
        :errors      => errors.inspect,
        :protocol    => (protocol.present? ? protocol.protocol : nil),
        :doc         => "'#{(doc||"")[0..30].gsub(/[\n\t\r]+/,' ')}...'",
      }
    end
  end

  Type.class_eval do
    def inspect
      ["#<#{self.class.name}",
        @type,
        inspect_hsh.map{|k,v| "#{k}=#{v}" },
        ">",
      ].compact.join(" ")
    end
  private
    def inspect_hsh
      { :name        => name,
        :doc         => "'#{(doc||"")[0..30].gsub(/[\n\t\r]+/,' ')}...'", }
    end
  end

  RecordField.class_eval do
    def inspect
      ["#<#{self.class.name}",
        inspect_hsh.map{|k,v| "#{k}=#{v}" },
        ">",
      ].compact.join(" ")
    end
  private
    def inspect_hsh
      { :name        => name,
        :type        => expand_type,
        :default     => default,
        :order       => @order,
        :doc         => "'#{(doc||"")[0..30].gsub(/[\n\t\r]+/,' ')}...'",
      }.reject{|k,v| v.nil? }
    end
  end

  PrimitiveType.class_eval do
    def inspect
      "#<#{self.class.name} #{name}>"
    end
  end

  NamedType.class_eval do
    private
    def inspect_hsh
      super.merge( :namespace => @namespace )
    end
  end

  RecordType.class_eval do
    private
    def inspect_hsh
      super.merge( :fields  => (fields||[]).inject({}){|h,f| h[f.name] = ((f.type.present? && f.is_reference?) ? f.type.name : f.type) ; h }.inspect )
    end
  end

  EnumType.class_eval do
    private
    def inspect_hsh
      super.merge( :symbols => symbols.inspect )
    end
  end

  FixedType.class_eval do
    private
    def inspect_hsh
      super.merge( :size    => size.inspect )
    end
  end

  ArrayType.class_eval do
    private
    def inspect_hsh
      super.merge( :items   => items.inspect )
    end
  end

  MapType.class_eval do
    private
    def inspect_hsh
      super.merge( :values  => values.inspect )
    end
  end

end

