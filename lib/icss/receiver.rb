require 'active_support/core_ext/class'
require 'time'

# dummy type for receiving True or False
class Boolean ; end unless defined?(Boolean)

# Receiver lets you describe complex (even recursive!) actively-typed data models that
# * are creatable or assignable from static data structures
# * perform efficient type conversion when assigning from a data structure,
# * but with nothing in the way of normal assignment or instantiation
# * and no requirements on the initializer
#
#    class Tweet
#      include Receiver
#      rcvr_accessor :id,           Integer
#      rcvr_accessor :user_id,      Integer
#      rcvr_accessor :created_at,   Time
#    end
#    p Tweet.receive(:id => "7", :user_id => 9, :created_at => "20101231010203" )
#     # => #<Tweet @id=7, @user_id=9, @created_at=2010-12-31 07:02:03 UTC>
#
# You can override receive behavior in a straightforward and predictable way:
#
#    class TwitterUser
#      include Receiver
#      rcvr_accessor :id,           Integer
#      rcvr_accessor :screen_name,  String
#      rcvr_accessor :follower_ids, Array, :of => Integer
#      # protect against receiving an id of "0" or ""
#      def receive_id(v)
#        raise "Missing id: #{v.inspect}" if v.to_i == 0
#        self.id = v
#      end
#    end
#
# The receiver pattern works naturally with inheritance:
#
#    class TweetWithUser < Tweet
#      rcvr_accessor :user, TwitterUser
#      def after_receive(hsh)
#        self.user_id = self.user.id if self.user
#      end
#    end
#    p TweetWithUser.receive(:id => 8675309, :created_at => "20101231010203", :user => { :id => 24601, :screen_name => 'bob', :follower_ids => [1, 8, 3, 4] })
#     => #<TweetWithUser @id=8675309, @created_at=2010-12-31 07:02:03 UTC, @user=#<TwitterUser @id=24601, @screen_name="bob", @follower_ids=[1, 8, 3, 4]>, @user_id=24601>
#
# TweetWithUser was able to add another receiver, applicable only to itself and its subclasses.
#
# The receive method is forgiving of sparse data:
#
#    tw = Tweet.receive(:id => "7", :user_id => 9 )
#    p tw
#    # => #<Tweet @id=7, @user_id=9>
#
#    tw.receive!(:created_at => "20101231010203" )
#    p tw
#    # => #<Tweet @id=7, @user_id=9, @created_at=2010-12-31 07:02:03 UTC>
#
# Note the distinction between an explicit nil field and a missing field:
#
#    tw.receive!(:user_id => nil, :created_at => "20090506070809" )
#    p tw
#    # => #<Tweet @id=7, @user_id=nil, @created_at=2009-05-06 12:08:09 UTC>
#
module Receiver

  RECEIVER_BODIES           = {} unless defined?(RECEIVER_BODIES)
  RECEIVER_BODIES[Symbol]   = %q{ v.to_sym }
  RECEIVER_BODIES[String]   = %q{ v.to_s }
  RECEIVER_BODIES[Integer]  = %q{ v.nil? ? nil : v.to_i }
  RECEIVER_BODIES[Float]    = %q{ v.nil? ? nil : v.to_f }
  RECEIVER_BODIES[Time]     = %q{ v.nil? ? nil : Time.parse(v.to_s).utc }
  RECEIVER_BODIES[Date]     = %q{ v.nil? ? nil : Date.parse(v.to_s) }
  RECEIVER_BODIES[Array]    = %q{ v.nil? ? nil : v }
  RECEIVER_BODIES[Hash]     = %q{ v.nil? ? nil : v }
  RECEIVER_BODIES[Boolean]  = %q{ v.nil? ? nil : (v.to_s.strip != "false") }
  RECEIVER_BODIES[NilClass] = %q{ raise "This field must be nil, but #{v} was given" unless (v.nil?) ; nil }
  RECEIVER_BODIES[Object]   = %q{ v } # accept and love the object just as it is
  RECEIVER_BODIES.each do |k,b|
    if k.is_a?(Class)
      k.class_eval <<-STR, __FILE__, __LINE__ + 1
      def self.receive(v)
        #{b}
      end
      STR
    end
  end

  TYPE_ALIASES = {
    :null    => NilClass,
    :boolean => Boolean,
    :string  => String,  :bytes   => String,
    :symbol  => Symbol,
    :int     => Integer, :integer => Integer,  :long    => Integer,
    :time    => Time,    :date    => Date,
    :float   => Float,   :double  => Float,
    :hash    => Hash,    :map     => Hash,
    :array   => Array,
  } unless defined?(TYPE_ALIASES)

  #
  # modify object in place with new typecast values.
  #
  def receive! hsh
    raise "Can't receive (it isn't hashlike): #{hsh.inspect}" unless hsh.respond_to?(:[])
    self.class.receiver_attr_names.each do |attr|
      if    hsh.has_key?(attr.to_sym) then val = hsh[attr.to_sym]
      elsif hsh.has_key?(attr.to_s)   then val = hsh[attr.to_s]
      else  next ; end
      _receive_attr attr, val
    end
    after_receive(hsh) if respond_to?(:after_receive)
    self
  end

  private
  def _receive_attr attr, val
    self.send("receive_#{attr}", val)
  end
  public


  module ClassMethods

    #
    # Returns a new instance with the given hash used to set all rcvrs.
    #
    # All args after the first are passed to the initializer.
    #
    def receive hsh, *args
      obj = self.new(*args)
      obj.receive!(hsh)
    end

    #
    # define a receiver attribute.
    # automatically generates an attr_accessor on the class if none exists
    #
    def rcvr name, type, info={}
      name = name.to_sym
      type = type_to_klass(type)
      class_eval  <<-STR, __FILE__, __LINE__ + 1
        def receive_#{name}(v)
          self.#{name} = #{receiver_body_for(type, info)}
        end
      STR
      receiver_attr_names << name unless receiver_attr_names.include?(name)
      receiver_attrs[name] = info.merge({ :name => name, :type => type })
    end

    def type_to_klass(type)
      case
      when type.is_a?(Class)                             then return type
      when TYPE_ALIASES.has_key?(type)                   then TYPE_ALIASES[type]
      # when (type.is_a?(Symbol) && type.to_s =~ /^[A-Z]/) then type.to_s.constantize
      else raise "Can\'t handle type #{type}: is it a Class or one of the TYPE_ALIASES? "
      end
    end

    # defines a receiver attribute, an attr_reader and an attr_writer
    # attr_reader is skipped if the getter method is already defined;
    # attr_writer is skipped if the setter method is already defined;
    def rcvr_accessor name, type, info={}
      attr_reader(name) unless method_defined?(name)
      attr_writer(name) unless method_defined?("#{name}=")
      rcvr name, type, info
    end
    # defines a receiver attribute and an attr_reader
    # attr_reader is skipped if the getter method is already defined.
    def rcvr_reader name, type, info={}
      attr_reader(name) unless method_defined?(name)
      rcvr name, type, info
    end
    # defines a receiver attribute and an attr_writer
    # attr_writer is skipped if the setter method is already defined.
    def rcvr_writer name, type, info={}
      attr_writer(name) unless method_defined?("#{name}=")
      rcvr name, type, info
    end

  private
    def receiver_body_for type, info
      type = type_to_klass(type)
      # Note that Array and Hash only need (and only get) special treatment when
      # they have an :of => SomeType option.
      case
      when info[:of] && (type == Array)
        %Q{ v.nil? ? nil : v.map{|el| #{info[:of]}.receive(el) } }
      when info[:of] && (type == Hash)
        %Q{ v.nil? ? nil : v.inject({}){|h, (el,val)| h[el] = #{info[:of]}.receive(val); h } }
      when Receiver::RECEIVER_BODIES.include?(type)
        Receiver::RECEIVER_BODIES[type]
      when type.is_a?(Class)
        %Q{v.blank? ? nil : #{type}.receive(v) }
      # when (type.is_a?(Symbol) && type.to_s =~ /^[A-Z]/)
      #   # a hack so you can use a class not defined yet
      #   %Q{v.blank? ? nil : #{type}.receive(v) }
      else
        raise("Can't receive #{type} #{info}")
      end
    end
  end

  # set up receiver attributes, and bring in methods from the ClassMethods module at class-level
  def self.included base
    base.class_eval do
      class_inheritable_accessor :receiver_attrs, :receiver_attr_names
      self.receiver_attrs      = {} # info about the attr
      self.receiver_attr_names = [] # ordered set of attr names
      extend ClassMethods
    end
  end
end
