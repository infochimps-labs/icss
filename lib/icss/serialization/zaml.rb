# -*- encoding: utf-8 -*-
#
# ZAML -- A partial replacement for YAML, writen with speed and code clarity
#         in mind.  ZAML fixes one YAML bug (loading Exceptions) and provides
#         a replacement for YAML.dump() unimaginatively called ZAML.dump(),
#         which is faster on all known cases and an order of magnitude faster
#         with complex structures.
#
# http://github.com/hallettj/zaml
#
# Authors: Markus Roberts, Jesse Hallett, Ian McIntosh, Igal Koshevoy, Simon Chiang
#

require 'yaml'

class ZAML
  VERSION = "0.1.4m"   unless defined?(::ZAML::VERSION)
  DEFAULT_VALIGN = 24  unless defined?(::ZAML::DEFAULT_VALIGN)

  attr_accessor :result, :indent
  # line up simple value tokens at this vertical column
  attr_accessor :valign

  #
  # Class Methods
  #
  def self.dump(stuff, where='', options={})
    z = self.new
    z.emit('--- ')
    stuff.to_zaml(z)
    where << z.to_s
  end

  #
  # Instance Methods
  #
  def initialize(options={})
    reset!
    self.valign = options[:valign]
  end

  def reset!
    @result = []
    @indent = nil
    @structured_key_prefix = nil
    Label.counter_reset
  end

  # for all code within the block, the cursor supplies
  def nested(tail='  ')
    old_indent = @indent
    # @indent    = "#{@indent || "\n"}#{tail}"
    @indent    = @indent ? "#{@indent}#{tail}" : "\n"
    yield
    @indent    = old_indent
  end

  def emit(s)
    @result << s
    @recent_nl = false unless s.kind_of?(Label)
  end
  def nl(s='')
    emit(@indent || "\n") unless @recent_nl
    emit(s)
    @recent_nl = true
  end
  def prefix_structured_keys(x)
    @structured_key_prefix = x
    yield
    nl unless @structured_key_prefix
    @structured_key_prefix = nil
  end
  # def vpadding
  #   return '' if (not @valign) || @recent_nl || result.empty?
  #   rp  = @valign - ((@indent || "\n").length - 1)
  #   rp -= @result.last.length
  #   rp > 0 ?
  # end

  def new_label_for(obj)
    Label.new(obj,(Hash === obj || Array === obj) ? "#{@indent || "\n"}  " : ' ')
  end
  def first_time_only(obj)
    if label = Label.for(obj)
      emit(label.reference)
    else
      if @structured_key_prefix and not obj.is_a? String
        emit(@structured_key_prefix)
        @structured_key_prefix = nil
      end
      emit(new_label_for(obj))
      yield
    end
  end

  def to_s
    @result.join
  end
  def inspect
    res = to_s
    res = res[0..46]+"..." if res.length > 50
    %Q{\#<ZAML ind=#{indent} pfx=#{structured_key_prefix} result='#{res}'>}
  end


  #
  # Label class -- resolves circular references
  #
  class Label
    #
    # YAML only wants objects in the datastream once; if the same object
    #    occurs more than once, we need to emit a label ("&idxxx") on the
    #    first occurrence and then emit a back reference (*idxxx") on any
    #    subsequent occurrence(s).
    #
    # To accomplish this we keeps a hash (by object id) of the labels of
    #    the things we serialize as we begin to serialize them.  The labels
    #    initially serialize as an empty string (since most objects are only
    #    going to be be encountered once), but can be changed to a valid
    #    (by assigning it a number) the first time it is subsequently used,
    #    if it ever is.  Note that we need to do the label setup BEFORE we
    #    start to serialize the object so that circular structures (in
    #    which we will encounter a reference to the object as we serialize
    #    it can be handled).
    #
    def self.counter_reset
      @@previously_emitted_object = {}
      @@next_free_label_number = 0
    end
    def initialize(obj,indent)
      @indent = indent
      @this_label_number = nil
      @@previously_emitted_object[obj.object_id] = self
    end
    def to_s
      @this_label_number ? ('&id%03d%s' % [@this_label_number, @indent]) : ''
    end
    def reference
      @this_label_number ||= (@@next_free_label_number += 1)
      @reference         ||= '*id%03d' % @this_label_number
    end
    def self.for(obj)
      @@previously_emitted_object[obj.object_id]
    end
  end

end

################################################################
#
#   Behavior for custom classes
#
################################################################

class Object
  def to_yaml_properties
    instance_variables.sort        # Default YAML behavior
  end
  def zamlized_class_name(root)
    "!ruby/#{root.name.downcase}#{self.class == root ? '' : ":#{self.class.name}"}"
  end
  def to_zaml(z)
    z.first_time_only(self) {
      z.emit(zamlized_class_name(Object))
      z.nested {
        instance_variables = to_yaml_properties
        if instance_variables.empty?
          z.emit(" {}")
        else
          instance_variables.each { |v|
            z.nl
            v[1..-1].to_zaml(z)       # Remove leading '@'
            z.emit(': ')
            instance_variable_get(v).to_zaml(z)
          }
        end
      }
    }
  end
end

################################################################
#
#   Behavior for built-in classes
#
################################################################

class NilClass
  def to_zaml(z)
    z.emit('')        # NOTE: blank turns into nil in YAML.load
  end
end

class Symbol
  def to_zaml(z)
    z.emit(self.inspect)
  end
end

class TrueClass
  def to_zaml(z)
    z.emit('true')
  end
end

class FalseClass
  def to_zaml(z)
    z.emit('false')
  end
end

class Numeric
  def to_zaml(z)
    z.emit(self)
  end
end

class Regexp
  def to_zaml(z)
    z.first_time_only(self) { z.emit("#{zamlized_class_name(Regexp)} #{inspect}") }
  end
end

class Exception
  def to_zaml(z)
    z.emit(zamlized_class_name(Exception))
    z.nested {
      z.nl("message: ")
      message.to_zaml(z)
    }
  end
  #
  # Monkey patch for buggy Exception restore in YAML
  #
  #     This makes it work for now but is not very future-proof; if things
  #     change we'll most likely want to remove this.  To mitigate the risks
  #     as much as possible, we test for the bug before appling the patch.
  #
  if respond_to? :yaml_new and yaml_new(self, :tag, "message" => "blurp").message != "blurp"
    def self.yaml_new( klass, tag, val )
      o = YAML.object_maker( klass, {} ).exception(val.delete( 'message'))
      val.each_pair do |k,v|
        o.instance_variable_set("@#{k}", v)
      end
      o
    end
  end
end

ZAML::NUM_RE    = '[-+]?(0x)?\d+\.?\d*' unless defined?(::ZAML::NUM_RE)
ZAML::SIMPLE_STRING_RE = /\A(true|false|yes|no|on|null|off|#{ZAML::NUM_RE}(:#{ZAML::NUM_RE})*|!|=|~)$/io unless defined?(::ZAML::SIMPLE_STRING_RE)
ZAML::ZAML_ESCAPES = %w{\x00 \x01 \x02 \x03 \x04 \x05 \x06 \a \x08 \t \n \v \f \r \x0e \x0f \x10 \x11 \x12 \x13 \x14 \x15 \x16 \x17 \x18 \x19 \x1a \e \x1c \x1d \x1e \x1f } unless defined?(ZAML::ZAML_ESCAPES)

ZAML::HI_BIT_CHARS = '\x80-\xFF'
if RUBY_VERSION > "1.9" then ZAML::HI_BIT_CHARS.force_encoding('ASCII-8BIT') ; end
ZAML::EXTENDED_CHARS_RE = /[\x00-\x08\x0B\x0C\x0E-\x1F#{ZAML::HI_BIT_CHARS}]/o

class String
  def escaped_for_zaml
    gsub( /\x5C/, "\\\\\\" ).  # Demi-kludge for Maglev/rubinius; the regexp should be /\\/ but parsetree chokes on that.
      gsub( /"/, "\\\"" ).
      gsub( /([\x00-\x1F])/ ){|x| ZAML::ZAML_ESCAPES[ x.unpack("C")[0] ] }.
      gsub( /([#{ZAML::HI_BIT_CHARS}])/ ){|x| "\\x#{x.unpack("C")[0].to_s(16)}" }
  end
  def to_zaml(z)
    z.first_time_only(self) {
      case
      when self == ''
        z.emit('""')
      when (self =~ ZAML::EXTENDED_CHARS_RE) #
        #   z.emit("!binary |") ;
        #   z.nested{ z.nl; z.emit([self].pack("m72")) }
        z.emit("\"#{escaped_for_zaml}\"")
      when (
          (self =~ ZAML::SIMPLE_STRING_RE) or
          (self =~ /\A\n* /) or
          (self =~ /[\s:]$/) or
          (self =~ /^[>|][-+\d]*\s/i) or
          (self[-1..-1] =~ /\s/) or
          (self =~ /[,\[\]\{\}\r\t]|:\s|\s#/) or
          (self =~ /\A([-:?!#&*'"]|<<|%.+:.)/)
          )
        z.emit("\"#{escaped_for_zaml}\"")
      when self =~ /\n/
        if self[-1..-1] == "\n" then z.emit('|+') else z.emit('|-') end
        z.nested { split("\n",-1).each { |line| z.nl; z.emit(line.chomp("\n")) } }
        z.nl
      else
        z.emit(self)
      end
    }
  end
end

class Hash
  def to_zaml(z)
    z.first_time_only(self) {
      z.nested {
        if empty?
          z.emit('{}')
        else
          each_pair { |k, v|
            z.nl
            z.prefix_structured_keys('? '){ k.to_zaml(z) }
            z.emit(': ')
            v.to_zaml(z)
          }
        end
      }
    }
  end
end

class Array
  def to_zaml(z)
    z.first_time_only(self) {
      z.nested {
        if empty?
          z.emit('[]')
        else
          each { |v| z.nl('- '); v.to_zaml(z) }
        end
      }
    }
  end
end

class Time
  def to_zaml(z)
    # 2008-12-06 10:06:51.373758 -07:00
    ms = ("%0.6f" % (usec * 1e-6)).sub(/^\d+\./,'')
    offset = "%+0.2i:%0.2i" % [utc_offset / 3600, (utc_offset / 60) % 60]
    z.emit(self.strftime("%Y-%m-%d %H:%M:%S.#{ms} #{offset}"))
  end
end

class Date
  def to_zaml(z)
    z.emit(strftime('%Y-%m-%d'))
  end
end

class Range
  def to_zaml(z)
    z.first_time_only(self) {
      z.emit(zamlized_class_name(Range))
      z.nested {
        z.nl
        z.emit('begin: ')
        z.emit(first)
        z.nl
        z.emit('end: ')
        z.emit(last)
        z.nl
        z.emit('excl: ')
        z.emit(exclude_end?)
      }
    }
  end
end

