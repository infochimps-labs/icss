module Icss

  Message.class_eval do
    def query_string
      request.first.type.fields.map do |field|
        "#{field.name}="
      end.join("&")
    end

    def api_url
      "http://api.infochimps.com#{path}.json?#{query_string}"
    end
  end

end
