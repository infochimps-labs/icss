require 'rubygems' unless defined?(Gem)
require 'spork'
require 'rspec'

ICSS_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__),'..'))
def ICSS_ROOT_DIR *paths
  File.join(::ICSS_ROOT_DIR, *paths)
end

Spork.prefork do # Must restart for changes to config / code from libraries loaded here
  $LOAD_PATH.unshift(ICSS_ROOT_DIR('lib'))
  $LOAD_PATH.unshift(ICSS_ROOT_DIR('spec/support'))
  Dir[ICSS_ROOT_DIR('spec/support/matchers/*.rb')].each {|f| require f}

  # Configure rspec
  RSpec.configure do |config|
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end
