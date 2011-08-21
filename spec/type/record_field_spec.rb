require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'icss'

module Icss::Smurf
  class Handy
    include Icss::Meta::RecordModel
  end
end

describe Icss::Meta::RecordType do
  before{ class Brawny < Icss::Smurf::Handy ; end }

  context '.field' do
    it 'adds RecordFields'
  end
end
