#
# Doing
#
#     require 'icss/brevity'
#
# makes the #inspect method on Icss::Type's be nice and readable, not GIGANTE
# PIQUANTE OY CABRON
#
#
module Icss
  Type.class_eval do
    def inspect_with_brevity
      ["#<#{self.class.name}",
        inspect_hsh.map{|k,v| "#{k}=#{v}" },
        ">",
      ].join(" ")
    end

  private
    def inspect_hsh
      {
        :name        => name,
        :type        => type,
        :doc         => "'#{(doc||"")[0..30].gsub(/[\n\t\r]+/,' ')}...'",
    }
    end
  end

  RecordType.class_eval do
    private
    # stuff a compact cartoon of the fields in there
    def inspect_hsh
      super.merge(
        :fields => (fields||[]).inject({}){|h,f| h[f.name] = f.type ; h }.inspect
        )
    end
  end

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
        :namespace   => namespace,
        :types       => (types||[]).map(&:name).inspect,
        :messages    => (messages||{}).values.map(&:name).inspect,
        :data_assets => (data_assets||[]).map(&:name).inspect,
        :doc         => "'#{(doc||"")[0..30].gsub(/[\n\t\r]+/,' ')}...'",
      }
    end
  end

end

