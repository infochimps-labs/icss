module Icss
  module Primitive

    class Text       < String ; end
    class FilePath   < String ; end
    class Regexp     < String ; end
    class Url        < String ; end
    class EpochTime < Integer ; end

    [Text, FilePath, Regexp, Url].each do |klass|
      Icss::Meta::RecordType::ReceiverDecorators::RECEIVER_BODIES[klass] = RECEIVER_BODIES[String]
    end
    Icss::Meta::RecordType::ReceiverDecorators::RECEIVER_BODIES[EpochTime] = RECEIVER_BODIES[Integer]

    Icss::Meta::SIMPLE_TYPES.merge!({
        :text      => Text,
        :file_path => FilePath,
        :regexp    => Regexp,
        :slug      => Slug,
        :url       => Url,
        :epoch_time => EpochTime,
      })

    # class Apikey     < String ; end
    # class BCryptHash < String ; end
    # class URI        < String ; end
    # class UUID       < String ; end
    # class Slug       < String ; end
    # class CommaSeparatedList < String ; end
    # class Csv                < String ; end
    # class IpAddress          < String ; end
    # class Json               < String ; end
    # class Yaml               < String ; end
    # class Enum ; end
    # class Flag ; end
    # class Discriminator ; end
    # class Duration
    #   def initialize(t1_t2)
    #     receive_times(t1_t2)
    #   end
    #
    #   def receive_times(t1_t2)
    #     self.t1, self.t2 = t1_t2
    #   end
    #
    #   def receive!(t1_t2)
    #     receive_times(t1_t2)
    #     super({})
    #   end
    # end

  end
end
