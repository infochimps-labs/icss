require 'spork'
require 'rspec'

def ENV.root_path(*args)
  File.expand_path(File.join(File.dirname(__FILE__), '..', *args))
end

Spork.prefork do # Must restart for changes to config / code from libraries loaded here
  $LOAD_PATH.unshift(ENV.root_path('lib'))
  Dir[ENV.root_path('spec/support/matchers/*.rb')].each {|f| require f}

  require 'awesome_print'

  require 'gorillib/object/blank'
  require 'gorillib/object/try_dup'
  require 'gorillib/string/inflections'
  require 'gorillib/string/constantize'
  require 'gorillib/array/compact_blank'
  require 'gorillib/array/extract_options'
  require 'gorillib/hash/compact'
  require 'gorillib/hash/keys'
  require 'gorillib/hash/tree_merge'
  require 'gorillib/metaprogramming/class_attribute'
  require 'gorillib/hashlike'

  require 'yaml'
  require 'json' unless defined?(JSON)

  # note: please do NOT include library methods here.
  # They should be painfully explicity included in your specs.

  # Configure rspec
  RSpec.configure do |config|
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end
