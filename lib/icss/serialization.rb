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
