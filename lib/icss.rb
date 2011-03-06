require 'active_support/inflector' # for classify and constantize
require 'active_support/core_ext/hash/keys'

$: << File.dirname(__FILE__)
require 'icss/receiver'
require 'icss/type'
require 'icss/message'
require 'icss/data_asset'
require 'icss/code_asset'
require 'icss/target'
require 'icss/protocol'
