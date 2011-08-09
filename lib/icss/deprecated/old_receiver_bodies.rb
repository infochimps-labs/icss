
      RECEIVER_BODIES           = {} unless defined?(RECEIVER_BODIES)
      RECEIVER_BODIES[NilClass] = lambda{|v| raise ArgumentError, "This field must be nil, but [#{v}] was given" unless (v.nil?) ; nil }
      RECEIVER_BODIES[Boolean]  = lambda{|v| case when v.nil? then nil when v.to_s.strip.blank? then false else v.to_s.strip != "false" end }
      RECEIVER_BODIES[Integer]  = lambda{|v| v.blank? ? nil : v.to_i }
      RECEIVER_BODIES[Float]    = lambda{|v| v.blank? ? nil : v.to_f }
      RECEIVER_BODIES[String]   = lambda{|v| v.to_s }
      #
      RECEIVER_BODIES[Symbol]   = lambda{|v| v.blank? ? nil : v.to_sym }
      RECEIVER_BODIES[Time]     = lambda{|v| v.nil?   ? nil : Time.parse(v.to_s).utc rescue nil }
      RECEIVER_BODIES[Date]     = lambda{|v| v.nil?   ? nil : Date.parse(v.to_s)     rescue nil }
      #
      RECEIVER_BODIES[Object]   = lambda{|v| v } # accept and love the object just as it is
      #
      RECEIVER_BODIES[Array]    = lambda{|v| case when v.nil? then nil when v.blank? then [] else Array(v) end }
      RECEIVER_BODIES[Hash]     = lambda{|v| case when v.nil? then nil when v.blank? then {} else v        end }
      #
      # Give each base class a receive method
      RECEIVER_BODIES.each do |k,b|
        if k.is_a?(Class) && (k != Object)
          k.class_eval{ define_singleton_method(:receive, &b) }
        end
      end

      def self.receiver_body_for type, schema
        # Note that Array and Hash only need (and only get) special treatment when
        # they have an :of => SomeType option.
        case
        when schema[:of] && (type == Array)
          receiver_type = schema[:of]
          lambda{|v|  v.nil? ? nil : v.map{|el| receiver_type.receive(el) } }
        when schema[:of] && (type == Hash)
          receiver_type = schema[:of]
          lambda{|v| v.nil? ? nil : v.inject({}){|h, (el,val)| h[el] = receiver_type.receive(val); h } }
        when RECEIVER_BODIES.include?(type)
          RECEIVER_BODIES[type]
        when type.respond_to?(:receive)
          lambda{|v| v.blank? ? nil : type.receive(v) }
        else
          raise("Can't receive #{type} #{schema}")
        end
      end
