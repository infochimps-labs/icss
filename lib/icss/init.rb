require 'icss'
require 'icss/view_helper'
Settings[:catalog_root] ||= Rails.root.to_s+'infochimps_catalog' if defined?(Rails) && !Rails.root.nil?