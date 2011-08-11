require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss/type'
require 'icss/entity'
require 'icss/receiver_model/active_model_shim'
require 'icss/type/primitive_types'
require 'icss/type/simple_types'
require 'icss/type/has_fields'
require 'icss/type/record_type'
require 'icss/type/named_schema'
require 'icss/type/type_factory'
require 'icss/type/complex_types'
require 'icss/type/record_field'

require 'yaml'

def example_files(filename)
  Dir[ENV.root_path('examples/infochimps-catalog', filename+".icss.yaml")]
end

icss_filenames = %w[
schema_org/thing schema_org/place
].map{|fn| example_files(fn) }.flatten

icss_filenames[0..2].each do |icss_filename|
  hsh = YAML.load(File.open(icss_filename))
  p hsh.keys

  hsh['types'].each do |schema|
    ap schema
    type_klass = Icss::Meta::TypeFactory.receive(schema)
    ap type_klass

  end
end
