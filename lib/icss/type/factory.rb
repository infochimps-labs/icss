module Icss
  class SynthesizedType
    include Receiver

    def initialize *args
      receive! *args unless args.empty?
    end
  end

  class RecordType < NamedType

    def ruby_klass_scope_names
      fullname.split('.').map(&:classify)
    end
    def ruby_klass_name
      "::" + ruby_klass_scope_names.join('::')
    end
    def ruby_klass_parent
      ("::" + ruby_klass_scope_names[0..-2].join('::')).constantize
    end

    def ensure_parent_modules!
      ruby_klass_scope_names[0..-2].inject(Object) do |parent_module, module_name|
        new_parent   = "::#{parent_module}::#{module_name}".constantize rescue nil
        new_parent ||= parent_module.const_set(module_name.to_sym, Module.new)
        # p [parent_module, new_parent, module_name]
        new_parent
      end
    end

    def define_klass
      ensure_parent_modules!
      parent_module = ruby_klass_parent
      klass_basename = ruby_klass_scope_names.last.to_sym
      klass   = parent_module.const_get(klass_basename) rescue nil
      klass ||= parent_module.const_set(klass_basename, Class.new(::Icss::SynthesizedType))
      klass
    end

    def ruby_klass
      return @klass if @klass
      klass = define_klass
      decorate_with_receivers(klass)
      decorate_with_conveniences(klass)
      @klass = klass
    end

    def decorate_with_receivers klass
      fields.each do |field|
        field.define_receiver_on(klass)
      end
    end

    def decorate_with_conveniences klass
      klass.send :include, Receiver::ActsAsHash
    end

  end

  Icss::RecordField.class_eval do
    def define_receiver_on(klass)
      klass.rcvr_accessor name.to_sym, type.ruby_klass
    end
  end
end
