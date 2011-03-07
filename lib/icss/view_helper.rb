module Icss
  Protocol.class_eval do

  end

  Message.class_eval do
    def query_string
      # request.first.fields.map do |field| "#{field.name}=[value]"
      # end.join("&")
      request.first.fields.inspect
    end

    def api_url
      "http://api.infochimps.com#{path}.json?#{query_string}"
    end
  end

  Type.class_eval do
    def to_html
      %Q{<code>#{name}</code> (<code>#{type}</code>): #{textilize(doc)}}
    end
  end

  RecordType.class_eval do
    def to_html
      [ super,
        "<ul>",
        field_types.map do |field|
          ["<li>", field.to_html, "</li>"]
        end,
      "</ul>\n"].flatten.join
    end
  end

end
