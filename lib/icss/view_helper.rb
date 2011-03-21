module Icss
  Message.class_eval do

    def query_string
      fields = request.first.type.fields     rescue nil ; return unless fields
      fields.map do |field|
        "#{field.name}=#{first_sample_request_param[field.name.to_s]}"
      end.join("&")
    end

    def api_url
      "http://api.infochimps.com/#{path}.json?#{query_string}"
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
