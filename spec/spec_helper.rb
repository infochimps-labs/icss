require 'rubygems'
require 'spork'
require 'rspec'

def ENV.root_path(*args)
  File.expand_path(File.join(File.dirname(__FILE__), '..', *args))
end

Spork.prefork do # Must restart for changes to config / code from libraries loaded here
  $LOAD_PATH.unshift(ENV.root_path('lib'))
  Dir[ENV.root_path('spec/support/matchers/*.rb')].each {|f| require f}

  # Configure rspec
  RSpec.configure do |config|
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end
