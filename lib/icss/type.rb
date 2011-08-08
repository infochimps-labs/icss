module Icss
  module Meta

    module Type
      def self.fullname_for(klass_name)
        klass_name.to_s.gsub(/^:*Icss::/, '').underscore.gsub(%r{/},".")
      end
      def self.klassname_for(fullname)
        nm = fullname.to_s.gsub(/^:*Icss:+/, '').
          gsub(%r{::},'.').
          split('.').map(&:camelize).join('::')
        "::Icss::#{nm}"
      end
      #
      def self.primitive?(tt) ::Icss::PRIMITIVE_TYPES.has_value?(tt) ; end
      def self.simple?(tt)    ::Icss::SIMPLE_TYPES.has_value?(tt)    ; end
      def self.union?(tt)     false     ; end
      def self.record?(tt)    false     ; end
      #
      def self.find_in_type_collection(type_collection, kind, typename)
        type_collection[typename.to_sym] or raise(ArgumentError, "No such #{kind} type #{typename}")
      end
      #
      module Schema
        def fullname
          ::Icss::Meta::Type.fullname_for(self.name)
        end
        def typename
          @typename  ||= fullname.to_s.gsub(/.*[\.]/, "")
        end
        def namespace
          @namespace ||= fullname.to_s.gsub(/\.[^\.]+\z/so, "")
        end

        def doc() "" ; end

        def to_schema
          # p [:to_schema, self, __FILE__]
          { :type => 'MISSING_SCHEMA' }
        end
        def self.included(base) base.class_eval{ def self.has_field_writers() extend(Icss::Meta::RecordType::Schema) ; end } end
      end
      def self.included(base) base.class_eval{ base.extend(Schema) } ; end
    end
    module SimpleType
      include Icss::Meta::Type
      #
      def self.make(typename)
        Icss::Meta::Type.find_in_type_collection(::Icss::SIMPLE_TYPES, :simple, typename)
      end
      module Schema
        include Icss::Meta::Type::Schema
        #
        def namespace()  ''       ; end
        def typename()   fullname ; end
        def to_schema()  fullname ; end
      end
      def self.included(base) base.class_eval{ base.extend(Schema) } ; end
    end
    module PrimitiveType
      include Icss::Meta::Type
      include Icss::Meta::SimpleType
      #
      def self.make(typename)
        Icss::Meta::Type.find_in_type_collection(::Icss::PRIMITIVE_TYPES, :primitive, typename)
      end
      module Schema
        include Icss::Meta::Type::Schema
        include Icss::Meta::SimpleType::Schema
      end
      def self.included(base) base.class_eval{ base.extend(Schema) } ; end
    end
  end


  class ::NilClass                ; include ::Icss::Meta::PrimitiveType ; def self.receive(val=nil) raise(ArgumentError, "#{self} must be initialized with nil") unless val.nil? ; nil ; end ; end
  class ::Boolean < ::BasicObject ; include ::Icss::Meta::PrimitiveType ; def self.receive(val=nil) case when v.nil? then nil when v.to_s.strip.blank? then false else v.to_s.strip != "false" end ; end
  class ::Integer                 ; include ::Icss::Meta::PrimitiveType ; def self.receive(val=nil) val.nil? ? nil : Integer(val) ; end ; end
  class ::Float                   ; include ::Icss::Meta::PrimitiveType ; def self.receive(val=nil) val.nil? ? nil : Float(val)   ; end ; end
  class ::String                  ; include ::Icss::Meta::PrimitiveType ; def self.receive(val=nil)                  String(val)  ; end ; end
  class ::Symbol                  ; include ::Icss::Meta::SimpleType    ; def self.receive(val=nil) val.nil? ? nil : val.to_sym ; end ; end
  class ::Time                    ; include ::Icss::Meta::SimpleType    ; def self.receive(val=nil) val.nil? ? nil : Time.parse(v.to_s).utc rescue nil ; end ; end
  class ::Date                    ; include ::Icss::Meta::SimpleType    ; def self.receive(val=nil) val.nil? ? nil : Date.parse(v.to_s).utc rescue nil ; end ; end
  class ::Long    < ::Integer     ; include ::Icss::Meta::PrimitiveType ; end
  class ::Double  < ::Float       ; include ::Icss::Meta::PrimitiveType ; end
  class ::Binary  < ::String      ; include ::Icss::Meta::PrimitiveType ; end

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

  ::Icss::PRIMITIVE_TYPES.each do |sym, klass|
    klass.class_eval do klass.singleton_class.class_eval do
        # Make fullname() return the symbol key given above
        define_method(:fullname){ sym }
      end ; end
  end
end
