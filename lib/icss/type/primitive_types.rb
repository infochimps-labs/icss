module Icss
  module Meta
    module ::Icss::Meta::NilClassSchema
      def receive(val=nil)
        raise(ArgumentError, "#{self} must be initialized with nil, but [#{val}] was given") unless val.nil?
        nil
      end
      def to_schema() :null ; end
    end
    module ::Icss::Meta::BooleanSchema
      def receive(val=nil)
        case when val.nil? then nil when val.to_s.strip.blank? then false else val.to_s.strip != "false" end
      end
      def to_schema() :boolean ; end
    end
    module ::Icss::Meta::IntegerSchema  ; def to_schema() :int    ; end ; def receive(val=nil) val.blank? ? nil : val.to_i                            ; end ; end
    module ::Icss::Meta::LongSchema     ; def to_schema() :long                                                                                       ; end ; end
    module ::Icss::Meta::FloatSchema    ; def to_schema() :float  ; end ; def receive(val=nil) val.blank? ? nil : val.to_f                            ; end ; end
    module ::Icss::Meta::DoubleSchema   ; def to_schema() :double                                                                                     ; end ; end
    module ::Icss::Meta::StringSchema   ; def to_schema() :string ; end ; def receive(val=nil) self.new(val.to_s)                                     ; end ; end
    module ::Icss::Meta::BinarySchema   ; def to_schema() :bytes                                                                                      ; end ; end
    #
    module ::Icss::Meta::SymbolSchema   ; def to_schema() :symbol ; end ; def receive(val=nil) val.blank? ? nil : val.to_sym                          ; end ; end
    module ::Icss::Meta::TimeSchema     ; def to_schema() :time   ; end ; def receive(val=nil) val.blank? ? nil : self.parse(val.to_s).utc rescue nil ; end ; end
    module ::Icss::Meta::DateSchema     ; def to_schema() :date   ; end ; def receive(val=nil) val.blank? ? nil : self.parse(val.to_s)     rescue nil ; end ; end
  end
end

class ::NilClass                ; self.extend ::Icss::Meta::NilClassSchema ; end
class ::Boolean < ::BasicObject ; self.extend ::Icss::Meta::BooleanSchema  ; end
class ::Integer                 ; self.extend ::Icss::Meta::IntegerSchema  ; end
class ::Long    < ::Integer     ; self.extend ::Icss::Meta::LongSchema     ; end
class ::Float                   ; self.extend ::Icss::Meta::FloatSchema    ; end
class ::Double  < ::Float       ; self.extend ::Icss::Meta::DoubleSchema   ; end
class ::String                  ; self.extend ::Icss::Meta::StringSchema   ; end
class ::Binary  < ::String      ; self.extend ::Icss::Meta::BinarySchema   ; end
#
class ::Symbol                  ; self.extend ::Icss::Meta::SymbolSchema   ; end
class ::Time                    ; self.extend ::Icss::Meta::TimeSchema     ; end
class ::Date                    ; self.extend ::Icss::Meta::DateSchema     ; end

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


