module Icss
  module Meta
    module NilClassSchema
      def receive(val=nil)
        raise(ArgumentError, "#{self} must be initialized with nil, but [#{val}] was given") unless val.nil?
        nil
      end
      def to_schema() :null ; end
    end
    module BooleanSchema
      def receive(val=nil)
        case when val.nil? then nil when val.to_s.strip.blank? then false else val.to_s.strip != "false" end
      end
      def to_schema() :boolean ; end
    end
    module IntegerSchema  ; def to_schema() fullname ; end ; def fullname() :int    ; end ; def receive(val=nil) val.blank? ? nil : val.to_i                            ; end ; end
    module LongSchema     ; def to_schema() fullname ; end ; def fullname() :long                                                                                       ; end ; end
    module FloatSchema    ; def to_schema() fullname ; end ; def fullname() :float  ; end ; def receive(val=nil) val.blank? ? nil : val.to_f                            ; end ; end
    module DoubleSchema   ; def to_schema() fullname ; end ; def fullname() :double                                                                                     ; end ; end
    module StringSchema   ; def to_schema() fullname ; end ; def fullname() :string ; end ; def receive(val=nil) self.new(val.to_s)                                     ; end ; end
    module BinarySchema   ; def to_schema() fullname ; end ; def fullname() :bytes                                                                                      ; end ; end
    #
    module SymbolSchema   ; def to_schema() fullname ; end ; def fullname() :symbol ; end ; def receive(val=nil) val.blank? ? nil : val.to_sym                          ; end ; end
    module TimeSchema     ; def to_schema() fullname ; end ; def fullname() :time   ; end ; def receive(val=nil) val.blank? ? nil : self.parse(val.to_s).utc rescue nil ; end ; end

    # patron saint of Simple Types (Structured Text)
    module St
      module St::FilePathSchema     ; def to_schema() :'st.file_path'     ; end ; end
      module St::RegexpSchema       ; def to_schema() :'st.regexp'        ; end ; end
      module St::UrlSchema          ; def to_schema() :'st.url'           ; end ; end
      module St::Md5HexdigestSchema ; def to_schema() :'st.md5_hexdigest' ; end ; end
    end
    # pasture wherein graze MeasurementUnits
    module Mu
      module Mu::EpochTimeSchema    ; def to_schema() :'mu.epoch_time' ; end ; end
    end
  end

  class ::NilClass                       ; self.extend ::Icss::Meta::NilClassSchema         ; end
  class ::Boolean        < ::BasicObject ; self.extend ::Icss::Meta::BooleanSchema          ; end
  class ::Integer                        ; self.extend ::Icss::Meta::IntegerSchema          ; end
  class ::Long           < ::Integer     ; self.extend ::Icss::Meta::LongSchema             ; end
  class ::Float                          ; self.extend ::Icss::Meta::FloatSchema            ; end
  class ::Double         < ::Float       ; self.extend ::Icss::Meta::DoubleSchema           ; end
  class ::String                         ; self.extend ::Icss::Meta::StringSchema           ; end
  class ::Binary         < ::String      ; self.extend ::Icss::Meta::BinarySchema           ; end
  #
  class ::Symbol                         ; self.extend ::Icss::Meta::SymbolSchema           ; end
  class ::Time                           ; self.extend ::Icss::Meta::TimeSchema             ; end

  class St::FilePath     < ::String      ; self.extend ::Icss::Meta::St::FilePathSchema     ; end
  class St::Regexp       < ::String      ; self.extend ::Icss::Meta::St::RegexpSchema       ; end
  class St::Url          < ::String      ; self.extend ::Icss::Meta::St::UrlSchema          ; end
  class St::Md5Hexdigest < ::String      ; self.extend ::Icss::Meta::St::Md5HexdigestSchema ; end
  class Mu::EpochTime    < ::Integer     ; self.extend ::Icss::Meta::Mu::EpochTimeSchema    ; end

  ::Icss::SIMPLE_TYPES.merge!({
      :'st.file_path'     => ::Icss::St::FilePath,
      :'st.regexp'        => ::Icss::St::Regexp,
      :'st.url'           => ::Icss::St::Url,
      :'st.md5_hexdigest' => ::Icss::St::Md5Hexdigest,
      :'mu.epoch_time'    => ::Icss::Mu::EpochTime,
    })

end

class ::Boolean < BasicObject
  attr_accessor :val
  def initialize(val=nil)
    self.val = val
  end
  def self.methods() ::TrueClass.methods | ::Icss::Meta::BooleanSchema.instance_methods ; end
  def method_missing(meth, *args)
    val.send(meth, *args)
  end
  def respond_to?(meth)
    super(meth) || val.respond_to?(meth)
  end
  def inspect()
    "<Boolean #{val.inspect}>"
  end
  def class()   ::Boolean          ; end
  def !()           (! val)          ; end
  def ==(other_val) val == other_val ; end
  def !=(other_val) val != other_val ; end
  def try_dup() ::Boolean.new(val) ; end
end

# Datamapper also defines:
#
#   Apikey BCryptHash URI UUID Slug CommaSeparatedList Csv IpAddress Json Yaml Enum Flag Discriminator
#
# maybe someday we will too...

