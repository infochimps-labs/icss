require 'icss/core_ext' unless Object.respond_to?(:class_attribute)
require 'gorillib/receiver'
require 'gorillib/receiver/acts_as_hash'
require 'gorillib/receiver/acts_as_loadable'
require 'gorillib/receiver/validations'
require 'time' # ain't that always the way

$: << File.dirname(__FILE__)
require 'icss/validations'
require 'icss/type'
require 'icss/message'
require 'icss/sample_message_call'
require 'icss/data_asset'
require 'icss/code_asset'
require 'icss/target'
require 'icss/protocol'

require 'icss/type/factory'
