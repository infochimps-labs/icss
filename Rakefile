require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "icss"
  gem.homepage = "http://github.com/mrflip/icss"
  gem.license = "MIT"
  gem.summary = %Q{Infochimps Simple Schema library: an avro-compatible data description standard. ICSS completely describes a collection of data (and associated assets) in a way that is expressive, scalable and sufficient to drive remarkably complex downstream processes.}
  gem.description = %Q{Infochimps Simple Schema library: an avro-compatible data description standard. ICSS completely describes a collection of data (and associated assets) in a way that is expressive, scalable and sufficient to drive remarkably complex downstream processes.}
  gem.email = "coders@infochimps.com"
  gem.authors = ["Philip (flip) Kromer for Infochimps"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
