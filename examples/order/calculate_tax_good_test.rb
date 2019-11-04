require 'minitest/autorun'
require 'order'
require 'calculate_tax_good'

describe CalculateTax do

  def init_order(params={})
    Order.new({
      region: 'USA',
      total: 100
    }.merge(params))
  end

  it 'tax and total for known region and valid total' do
    result = CalculateTax.call(init_order(total: 100, region: 'USA'))
    order = result.fetch(:order)

    order.tax.must_equal 10
    order.total_with_tax.must_equal 110
  end

  it 'tax range error for unknown region' do
    result = CalculateTax.call(init_order(region: 'China'))
    result.fetch(:error).must_equal 'The tax ranges were not found'
  end

  it 'tax percentage error for invalid total' do
    result = CalculateTax.call(init_order(total: 9999))
    result.fetch(:error).must_equal 'The tax percentage was not found'
  end

  it 'free shipping if more than 200' do
    result = CalculateTax.call(init_order(total: 333))
    order = result.fetch(:order)
    order.free_shipping.must_equal true
  end

  it 'no free shipping if less than 200' do
    result = CalculateTax.call(init_order(total: 10))
    order = result.fetch(:order)
    order.free_shipping.must_equal false
  end
end