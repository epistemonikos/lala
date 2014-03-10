class CarsController < ApplicationController
  def index
    @car = {name: 'escarabajo', year: '1970'}
  end
end
