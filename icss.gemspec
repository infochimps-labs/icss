# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "icss"
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Philip (flip) Kromer for Infochimps"]
  s.date = "2011-11-09"
  s.description = "Infochimps Simple Schema library: an avro-compatible data description standard. ICSS completely describes a collection of data (and associated assets) in a way that is expressive, scalable and sufficient to drive remarkably complex downstream processes."
  s.email = "coders@infochimps.com"
  s.extra_rdoc_files = [
    "LICENSE.textile"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".watchr",
    "Gemfile",
    "LICENSE.textile",
    "Rakefile",
    "TODO.md",
    "VERSION",
    "examples/avro_examples/BulkData.avpr",
    "examples/avro_examples/complicated.icss.yaml",
    "examples/avro_examples/interop.avsc",
    "examples/avro_examples/mail.avpr",
    "examples/avro_examples/namespace.avpr",
    "examples/avro_examples/org/apache/avro/ipc/HandshakeRequest.avsc",
    "examples/avro_examples/org/apache/avro/ipc/HandshakeResponse.avsc",
    "examples/avro_examples/org/apache/avro/ipc/trace/avroTrace.avdl",
    "examples/avro_examples/org/apache/avro/ipc/trace/avroTrace.avpr",
    "examples/avro_examples/org/apache/avro/mapred/tether/InputProtocol.avpr",
    "examples/avro_examples/org/apache/avro/mapred/tether/OutputProtocol.avpr",
    "examples/avro_examples/simple.avpr",
    "examples/avro_examples/weather.avsc",
    "examples/chronic.icss.yaml",
    "icss.gemspec",
    "icss_specification.textile",
    "lib/icss.rb",
    "lib/icss/message.rb",
    "lib/icss/protocol.rb",
    "lib/icss/type.rb",
    "lib/icss/view_helper.rb",
    "spec/icss_spec.rb",
    "spec/protocol_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/mrflip/icss"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "Infochimps Simple Schema library: an avro-compatible data description standard. ICSS completely describes a collection of data (and associated assets) in a way that is expressive, scalable and sufficient to drive remarkably complex downstream processes."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<activemodel>, ["~> 3.0.9"])
      s.add_runtime_dependency(%q<addressable>, ["~> 2.2"])
      s.add_runtime_dependency(%q<configliere>, ["~> 0.4.8"])
      s.add_runtime_dependency(%q<gorillib>, ["~> 0.1.7"])
      s.add_runtime_dependency(%q<addressable>, ["~> 2.2"])
      s.add_development_dependency(%q<bundler>, ["~> 1"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<awesome_print>, ["~> 0.4.0"])
    else
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<activemodel>, ["~> 3.0.9"])
      s.add_dependency(%q<addressable>, ["~> 2.2"])
      s.add_dependency(%q<configliere>, ["~> 0.4.8"])
      s.add_dependency(%q<gorillib>, ["~> 0.1.7"])
      s.add_dependency(%q<addressable>, ["~> 2.2"])
      s.add_dependency(%q<bundler>, ["~> 1"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<awesome_print>, ["~> 0.4.0"])
    end
  else
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<activemodel>, ["~> 3.0.9"])
    s.add_dependency(%q<addressable>, ["~> 2.2"])
    s.add_dependency(%q<configliere>, ["~> 0.4.8"])
    s.add_dependency(%q<gorillib>, ["~> 0.1.7"])
    s.add_dependency(%q<addressable>, ["~> 2.2"])
    s.add_dependency(%q<bundler>, ["~> 1"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<yard>, ["~> 0.6.0"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<awesome_print>, ["~> 0.4.0"])
  end
end

