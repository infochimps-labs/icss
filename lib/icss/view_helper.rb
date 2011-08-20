puts "!!!!!!!!!"
p __FILE__
puts "!!!!!!!!!"

module Icss
  module Meta
    Message.class_eval do

      def query_string
        req_fields = request.first.type.fields rescue nil ; return unless req_fields
        req_fields.map do |field|
          "#{field_name}=#{first_sample_request_param[field_name.to_s]}"
        end.join("&")
      end

      def api_url
        # all calls accept xml or json
        "http://api.infochimps.com/#{path}?#{query_string}"
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

  end
end
