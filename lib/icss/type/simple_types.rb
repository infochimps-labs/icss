module Icss
  module Meta
    module ::Icss::Meta::TextSchema       ; def to_schema() :text       ; end ; end
    module ::Icss::Meta::FilePathSchema   ; def to_schema() :file_path  ; end ; end
    module ::Icss::Meta::RegexpSchema     ; def to_schema() :regexp     ; end ; end
    module ::Icss::Meta::UrlSchema        ; def to_schema() :url        ; end ; end
    module ::Icss::Meta::EpochTimeSchema  ; def to_schema() :epoch_time ; end ; end
  end

  class Text       < ::String  ; self.extend ::Icss::Meta::TextSchema      ; end
  class FilePath   < ::String  ; self.extend ::Icss::Meta::FilePathSchema  ; end
  class Regexp     < ::String  ; self.extend ::Icss::Meta::RegexpSchema    ; end
  class Url        < ::String  ; self.extend ::Icss::Meta::UrlSchema       ; end
  class EpochTime  < ::Integer ; self.extend ::Icss::Meta::EpochTimeSchema ; end

  ::Icss::SIMPLE_TYPES.merge!({
      :text       => ::Icss::Text,
      :file_path  => ::Icss::FilePath,
      :regexp     => ::Icss::Regexp,
      :url        => ::Icss::Url,
      :epoch_time => ::Icss::EpochTime,
    })


  # Datamapper also defines:
  #
  #   Apikey BCryptHash URI UUID Slug CommaSeparatedList Csv IpAddress Json Yaml Enum Flag Discriminator
  #
  # maybe someday we will too...

end

