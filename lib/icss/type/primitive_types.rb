module Icss
  module Meta
    module ::Icss::Meta::NilClassType
      def receive(val=nil)
        raise(ArgumentError, "#{self} must be initialized with nil, but [#{val}] was given") unless val.nil?
        nil
      end
      def to_schema() :null ; end
    end
    module ::Icss::Meta::BooleanType
      def receive(val=nil)
        case when val.nil? then nil when val.to_s.strip.blank? then false else val.to_s.strip != "false" end
      end
      def to_schema() :boolean ; end
    end
    module ::Icss::Meta::IntegerType  ; def to_schema() :int    ; end ; def receive(val=nil) val.blank? ? nil : val.to_i                            ; end ; end
    module ::Icss::Meta::LongType     ; def to_schema() :long                                                                                       ; end ; end
    module ::Icss::Meta::FloatType    ; def to_schema() :float  ; end ; def receive(val=nil) val.blank? ? nil : val.to_f                            ; end ; end
    module ::Icss::Meta::DoubleType   ; def to_schema() :double                                                                                     ; end ; end
    module ::Icss::Meta::StringType   ; def to_schema() :string ; end ; def receive(val=nil) self.new(val.to_s)                                     ; end ; end
    module ::Icss::Meta::BinaryType   ; def to_schema() :bytes                                                                                      ; end ; end
    #
    module ::Icss::Meta::SymbolType   ; def to_schema() :symbol ; end ; def receive(val=nil) val.blank? ? nil : val.to_sym                          ; end ; end
    module ::Icss::Meta::TimeType     ; def to_schema() :time   ; end ; def receive(val=nil) val.blank? ? nil : self.parse(val.to_s).utc rescue nil ; end ; end
    module ::Icss::Meta::DateType     ; def to_schema() :date   ; end ; def receive(val=nil) val.blank? ? nil : self.parse(val.to_s)     rescue nil ; end ; end
  end
end

class ::NilClass                ; self.extend ::Icss::Meta::NilClassType ; end
class ::Boolean < ::BasicObject ; self.extend ::Icss::Meta::BooleanType  ; end
class ::Integer                 ; self.extend ::Icss::Meta::IntegerType  ; end
class ::Long    < ::Integer     ; self.extend ::Icss::Meta::LongType     ; end
class ::Float                   ; self.extend ::Icss::Meta::FloatType    ; end
class ::Double  < ::Float       ; self.extend ::Icss::Meta::DoubleType   ; end
class ::String                  ; self.extend ::Icss::Meta::StringType   ; end
class ::Binary  < ::String      ; self.extend ::Icss::Meta::BinaryType   ; end
#
class ::Symbol                  ; self.extend ::Icss::Meta::SymbolType   ; end
class ::Time                    ; self.extend ::Icss::Meta::TimeType     ; end
class ::Date                    ; self.extend ::Icss::Meta::DateType     ; end

unless defined?(::Icss::PRIMITIVE_TYPES)
  ::Icss::PRIMITIVE_TYPES = {
    :null     => ::NilClass,
    :boolean  => ::Boolean,
    :int      => ::Integer,
    :long     => ::Long,
    :float    => ::Float,
    :double   => ::Double,
    :string   => ::String,
    :bytes    => ::Binary,
  }.freeze
end

unless defined?(::Icss::SIMPLE_TYPES)
  ::Icss::SIMPLE_TYPES = ::Icss::PRIMITIVE_TYPES.merge({
      :symbol => ::Symbol,
      :time   => ::Time,
      :date   => ::Date,
    })
end

class Boolean < BasicObject
  attr_accessor :val
  def initialize(val=nil)
    self.val = val
  end
  def self.methods() ::TrueClass.methods | ::Icss::Meta::BooleanType.instance_methods ; end
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


