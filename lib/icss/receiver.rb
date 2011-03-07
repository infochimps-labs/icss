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
  mattr_accessor :receiver_bodies
  self.receiver_bodies           = {}
  self.receiver_bodies[Symbol]   = %q{ v.to_sym }
  self.receiver_bodies[String]   = %q{ v.to_s }
  self.receiver_bodies[Integer]  = %q{ v.nil? ? nil : v.to_i }
  self.receiver_bodies[Float]    = %q{ v.nil? ? nil : v.to_f }
  self.receiver_bodies[Time]     = %q{ v.nil? ? nil : Time.parse(v).utc }
  self.receiver_bodies[Date]     = %q{ v.nil? ? nil : Date.parse(v) }
  self.receiver_bodies[Array]    = %q{ v.nil? ? nil : v }
  self.receiver_bodies[Hash]     = %q{ v.nil? ? nil : v }
  self.receiver_bodies[Boolean]  = %q{ v.nil? ? nil : (v.strip != "false") }
  self.receiver_bodies[NilClass] = %q{ raise "This field must be nil, but #{v} was given" unless (v.nil?) ; nil }
  self.receiver_bodies[Object]   = %q{ v } # accept and love the object just as it is
  self.receiver_bodies.each do |k,b|
    k.class_eval %Q{
      def self.receive(v)
        #{b}
      end
    }
  end
  { :int    => Integer, :integer => Integer,
    :time   => Time,    :date    => Date,
    :float  => Float,   :double  => Float,
    :symbol => Symbol,  :string  => String,
  }.each{|t_alias, t| self.receiver_bodies[t_alias] = self.receiver_bodies[t] }

  module ClassMethods
    #
    # define a receiver attribute.
    # automatically generates an attr_accessor on the class if none exists
    #
    def rcvr name, type, info={}
      name = name.to_sym
      class_eval %Q{
        def receive_#{name}(v)
          self.#{name} = #{receiver_body_for(type, info)}
        end
      }
      receiver_attr_names << name unless receiver_attr_names.include?(name)
      receiver_attrs[name] = { :name => name, :type => type, :info => info }
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

    # instantiate a new object and dispatch the hash for assignment. If your
    # class's initializer needs arguments you'll need to override this
    # method.
    def receive hsh
      obj = self.new
      obj.receive!(hsh)
      obj
    end

  private
    def receiver_body_for type, info
      # Note that Array and Hash only need (and only get) special treatment when
      # they have an :of => SomeType option.
      case
      when info[:of] && (type == Array || type == :array)
        %Q{ v.nil? ? nil : v.map{|el| #{info[:of]}.receive(el) } }
      when info[:of] && (type == Hash  || type == :hash || type == :map)
        %Q{ v.nil? ? nil : v.inject({}){|h, (el,val)| h[el] = #{info[:of]}.receive(val); h } }
      when Receiver.receiver_bodies.include?(type)
        Receiver.receiver_bodies[type]
      when type.is_a?(Class) || (type.is_a?(Symbol) && type.to_s =~ /^[A-Z]/)
        %Q{v.blank? ? nil : #{type}.receive(v) }
      else
        raise("Can't receive #{type} #{info}")
      end
    end
  end

  # modify object in place with new typecast values.
  def receive! hsh
    self.class.receiver_attr_names.each do |attr|
      if    hsh.has_key?(attr.to_sym) then self.send("receive_#{attr}", hsh[attr.to_sym])
      elsif hsh.has_key?(attr.to_s)   then self.send("receive_#{attr}", hsh[attr.to_s])
      end
    end
    after_receive(hsh) if respond_to?(:after_receive)
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
