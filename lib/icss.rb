require 'active_support/inflector' # for classify and constantize
require 'active_support/core_ext/hash/keys'
# require 'active_support/core_ext/hash/deep_merge'

$: << File.dirname(__FILE__)
require 'icss/receiver'
require 'icss/receiver/acts_as_hash'
require 'icss/receiver/acts_as_loadable'
#
require 'icss/validations'
require 'icss/type'
require 'icss/message'
require 'icss/sample_message_call'
require 'icss/data_asset'
require 'icss/code_asset'
require 'icss/target'
require 'icss/protocol'

require 'icss/type/factory'
