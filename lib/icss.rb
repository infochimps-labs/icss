p __FILE__
require 'gorillib/object/blank'
require 'gorillib/object/try_dup'
require 'gorillib/string/inflections'
require 'gorillib/string/constantize'
require 'gorillib/array/compact_blank'
require 'gorillib/array/extract_options'
require 'gorillib/hashlike'
require 'gorillib/hashlike/tree_merge'
require 'gorillib/hash/compact'
require 'gorillib/hash/keys'
require 'gorillib/hash/tree_merge'
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/serialization'
require 'gorillib/hashlike'
#
require 'configliere'
Settings.define :catalog_root, :type => :filename, :default => (defined?(Rails) ? (Rails.root+'catalog') : File.expand_path('../../infochimps_catalog', __FILE__))
#
require 'icss/error'
require 'icss/receiver_model/acts_as_hash'
require 'icss/receiver_model/acts_as_loadable'
require 'icss/receiver_model/active_model_shim'
require 'icss/receiver_model/validations'
require 'icss/receiver_model/acts_as_tuple'
#
require 'icss/type'                   #
require 'icss/type/simple_types'      # Boolean, Integer, ...
require 'icss/type/named_type'        # class methods for a named type: .metamodel .doc, .fullname, &c
require 'icss/type/record_type'       # class methods for a record model: .field, .receive,
require 'icss/type/record_model'      # instance methods for a record model
#
require 'icss/type/type_factory'      #
require 'icss/type/structured_schema' # generate type from array, hash, &c schema
require 'icss/type/union_schema'      # factory for instances based on type
require 'icss/type/record_schema'
require 'icss/type/record_field'
#
require 'icss/receiver_model'
require 'icss/serialization'
#
# require 'icss/message/sample_message_call'
require 'icss/message'
require 'icss/protocol/data_asset'
require 'icss/protocol/code_asset'
require 'icss/protocol/target'
require 'icss/protocol'
