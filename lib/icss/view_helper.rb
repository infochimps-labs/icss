module Icss

  Message.class_eval do
    def query_string
      fields = request.first.type.fields rescue nil ; return unless fields
      fields.map do |field|
        "#{field.name}="
      end.join("&")
    end

    def api_url
      "http://api.infochimps.com/#{path}.json?#{query_string}"
    end
  end

end
