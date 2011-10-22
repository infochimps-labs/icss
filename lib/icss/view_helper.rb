module Icss
  module Meta
    Message.class_eval do

      def query_string
        req_fields = request.first.type.fields rescue nil ; return unless req_fields
        req_fields.map do |field|
          "#{field.name}=#{first_sample_request_param[field.name.to_s]}"
        end.join("&")
      end

      def api_url
        # all calls accept xml or json
        "http://api.infochimps.com/#{path}?#{query_string}"
      end

      def sample_field_value(field)
        field_name = ((field.respond_to?(:name) && field.name) || field).to_s

        value =  first_sample_request_param[field_name]  # sample value for field
      end

    end

    RecordField.class_eval do
      def title
        return "!!missing!!" if type.blank?
        # case type
        # when ArrayType then "array of #{type.title} #{type.to_hash.inspect}"
        # else type.title
        # end
        type.title
      end
    end

    RecordType.class_eval do

      # * when :display_fields are listed in the :_doc_hints, their field names
      #   are split on '.' and mapped to the right nested RecordField objects:
      #   content_location.geo.longitude will give the field for
      #   content_location in the current type, the geo field in that type, and
      #   the longitude field object in that type.
      # * if no :display_fields is given, return the full (flat) set of fields.
      #
      def display_fields
        df_names = self._doc_hints[:display_fields]
        return fields.map{|f| [f] } if df_names.blank?
        df_names.map do |fn|
          name_segs = fn.split('.')
          type = self
          sub_fields = []
          name_segs.map do |name_seg|
            sub_fields << (type.field_named(name_seg) || name_seg)
            type = sub_fields.last.type if sub_fields.last.respond_to?(:type)
            type = type.items if type.respond_to?(:items)
            type = type.values if type.respond_to?(:values)
          end
          sub_fields
        end
      end

    end

  end
end
