module Icss
  class Text       < ::Icss::StringType  ; include ::Icss::Meta::SimpleType ; end
  class FilePath   < ::Icss::StringType  ; include ::Icss::Meta::SimpleType ; end
  class Regexp     < ::Icss::StringType  ; include ::Icss::Meta::SimpleType ; end
  class Url        < ::Icss::StringType  ; include ::Icss::Meta::SimpleType ; end
  class EpochTime  < ::Icss::IntegerType ; include ::Icss::Meta::SimpleType ; end

  Icss::SIMPLE_TYPES.merge!({
      :text       => ::Icss::Text,
      :file_path  => ::Icss::FilePath,
      :regexp     => ::Icss::Regexp,
      :url        => ::Icss::Url,
      :epoch_time => ::Icss::EpochTime,
    })

  # Make fullname() return the symbol key given above
  ::Icss::SIMPLE_TYPES.each do |sym, klass|
    klass.class_eval{ klass.singleton_class.class_eval{ define_method(:fullname){ sym } } }
  end

  class BooleanType < BasicObject
    attr_accessor :val
    def initialize(val=nil)
      self.val = val
    end
    def self.methods() ::TrueClass.methods | ::Icss::Meta::PrimitiveType::Schema.instance_methods ; end
    def method_missing(meth, *args)
      val.send(meth, *args)
    end
    def respond_to?(meth)
      super(meth) || val.respond_to?(meth)
    end
    def inspect()
      "<BooleanType #{val.inspect}>"
    end
    def class()   BooleanType          ; end
    def !()           (! val)          ; end
    def ==(other_val) val == other_val ; end
    def !=(other_val) val != other_val ; end
    def try_dup() BooleanType.new(val) ; end
  end

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

  # class Apikey             < ::Icss::StringType ; end
  # class BCryptHash         < ::Icss::StringType ; end
  # class URI                < ::Icss::StringType ; end
  # class UUID               < ::Icss::StringType ; end
  # class Slug               < ::Icss::StringType ; end
  # class CommaSeparatedList < ::Icss::StringType ; end
  # class Csv                < ::Icss::StringType ; end
  # class IpAddress          < ::Icss::StringType ; end
  # class Json               < ::Icss::StringType ; end
  # class Yaml               < ::Icss::StringType ; end
  # class Enum ; end
  # class Flag ; end
  # class Discriminator ; end

end
