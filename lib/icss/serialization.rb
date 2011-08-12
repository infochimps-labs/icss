module Icss
  module Meta
    class RecordField
      def as_json()
        { :name     => name,
          :type     => expand_type,
          :doc      => doc,
          :default  => default,
          :required => required,
          :order    => @order,
        }.reject{|k,v| v.nil? }
      end

    protected
      def expand_type
        case
        when is_reference? && type.respond_to?(:fullname) then type.fullname
        when is_reference?                            then '(_unspecified_)'
        when type.is_a?(Array)                        then type.map{|t| t.to_hash }
        when type.respond_to?(:to_hash)               then type.to_hash
        else type.to_s
        end
      end
    end
  end
end


module Icss::ReceiverModel
  def as_json(*args)
    {}.tap{|hsh| self.each{|k,v| hsh[k] = (v.respond_to?(:as_json) ? v.as_json : v) } }
    # to_hash.compact_blank
  end
  def to_json(*args)
    as_json.to_json(*args)
  end
end

class Time
  def as_json
    self.iso8601
  end
end
