module Icss
  module Meta
    # patron saint of Simple Types (Structured Text)
    module St
      module ::Icss::Meta::St::FilePathSchema     ; def to_schema() :'file_path'  ; end ; end
      module ::Icss::Meta::St::RegexpSchema       ; def to_schema() :'regexp'     ; end ; end
      module ::Icss::Meta::St::UrlSchema          ; def to_schema() :'url'        ; end ; end
      module ::Icss::Meta::St::Md5HexdigestSchema ; def to_schema() :'st.md5_hexdigest' ; end ; end
    end
    # pasture wherein graze MeasurementUnits
    module Mu
      module ::Icss::Meta::Mu::EpochTimeSchema  ; def to_schema() :epoch_time ; end ; end
    end
  end

  module St
    class FilePath     < ::String  ; self.extend ::Icss::Meta::St::FilePathSchema     ; end
    class Regexp       < ::String  ; self.extend ::Icss::Meta::St::RegexpSchema       ; end
    class Url          < ::String  ; self.extend ::Icss::Meta::St::UrlSchema          ; end
    class Md5Hexdigest < ::String  ; self.extend ::Icss::Meta::St::Md5HexdigestSchema ; end
  end
  module Mu
    class EpochTime  < ::Integer ; self.extend ::Icss::Meta::Mu::EpochTimeSchema ; end
  end

  ::Icss::SIMPLE_TYPES.merge!({
      :file_path  => ::Icss::St::FilePath,
      :regexp     => ::Icss::St::Regexp,
      :url        => ::Icss::St::Url,
      #
      :epoch_time => ::Icss::Mu::EpochTime,
    })


  # Datamapper also defines:
  #
  #   Apikey BCryptHash URI UUID Slug CommaSeparatedList Csv IpAddress Json Yaml Enum Flag Discriminator
  #
  # maybe someday we will too...

end

