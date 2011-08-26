module Icss
  class NotFoundError      < ::NameError     ; end unless defined?(NotFoundError)
  class FactoryTypeMissing < ::ArgumentError ; end unless defined?(FactoryTypeMissing)
end
