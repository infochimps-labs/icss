module IcssTestHelper
  FALSE_PARENTS = %w[Boolean Icss::Mu::EpochTime Long Double]

  SIMPLE_TYPES_TO_TEST = {
    :null               => [ ::NilClass,              NilClass,   nil],
    :boolean            => [ ::Boolean,               TrueClass, true],
    :int                => [ ::Integer,               Integer,      1],
    :long               => [ ::Long,                  Integer,      1],
    :float              => [ ::Float,                 Float,      1.0],
    :double             => [ ::Double,                Float,      1.0],
    :string             => [ ::String,                String, "hello"],
    :bytes              => [ ::Binary,                String, "hello"],
    :binary             => [ ::Binary,                String, "hello"],
    :integer            => [ ::Integer,               Integer,      1],
    :regexp             => [ ::Regexp,                Regexp,     /a/],
    :numeric            => [ ::Numeric,               ::Numeric,  1.0],
    :symbol             => [ ::Symbol,                Symbol,    :bob],
    :time               => [ ::Time,                  Time,  Time.now],
  }


  def remove_icss_constants(*names)
    ['Icss', 'Icss::Meta'].each do |outer_mod|
      names.each do |name|
        name_parts = name.to_s.split(/::/)
        const_name = name_parts.pop
        parent_mod = ([outer_mod]+name_parts).join('::')
        ['', 'Type', 'Model'].each do |tail|
          remove_potential_constant(parent_mod, const_name+tail)
        end
      end
    end
  end

  def remove_potential_constant(parent_mod, const_name)
    begin
      parent_mod = (parent_mod.is_a?(Module) ? parent_mod : parent_mod.to_s.constantize)
    rescue ; return ; end
    parent_mod.send(:remove_const, const_name) if parent_mod.const_defined?(const_name)
  end
end

module Icss
  module This
    module That
      class TheOther
      end
    end
    module Blinken ; end
  end
end

if defined?(Icss::Meta::RecordModel)
  module Icss
    class SmurfRecord
      include Icss::Meta::RecordModel
    end
  end
end

if defined?(Icss::ReceiverModel)
  module Icss
    class SmurfModel
      include Icss::ReceiverModel
    end
  end
end
