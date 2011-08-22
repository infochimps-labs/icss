require File.expand_path('spec_helper', File.dirname(__FILE__))
require 'time'
require 'icss'
require ENV.root_path('spec/support/icss_test_helper')
include IcssTestHelper

module Fake
  class Thing
    include Icss::ReceiverModel
    field :name, String
    field :description, String
  end

  class GeoCoordinates
    include Icss::ReceiverModel
    field :longitude, Float, :validates => { :numericality => { :>= => -180, :<= => 180  } }
    field :latitude,  Float, :validates => { :numericality => { :>= =>  -90, :<= =>  90  } }
    def coordinates
      [ longitude, latitude ]
    end
  end

  class Place < Thing
    field :geo, GeoCoordinates
  end

  class MenuItem < Thing
    field :price, Float, :required => true
  end

  class TacoTrailer < Place
    field :menu,          Array, :items => MenuItem
    field :founding_date, Time
  end
end

TORCHYS_HSH = {
  :name => "Torchy's Taco's",
  :geo  => { :longitude => 30.295, :latitude => -97.745 },
  :menu => [
    { :name => "Dirty Sanchez", :price => 3.50 },
    { :name => "Fried Avocado", :price => 2.95 }
  ],
  :founding_date => '2006-08-01T00:00:00Z',
}

describe Icss::ReceiverModel do
  let(:torchys) do
    Fake::TacoTrailer.receive(TORCHYS_HSH)
  end

  context 'serializations' do

    context '#to_wire' do
      it 'works on a complex record' do
        torchys.to_wire.should == TORCHYS_HSH
      end
    end
  end

end
