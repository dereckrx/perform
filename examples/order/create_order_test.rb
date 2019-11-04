require 'minitest/autorun'
require 'railway'
require 'order'
require 'create_order'
require 'user'

describe CreateOrder do

  let(:order) { Order.new('USA') }
  let(:user) { User.new('USA', true) }

  it 'calls order' do
    result = CreateOrder.call(user, 100)
    order = result.value[:order]
    order.total.must_equal 110
  end

  it 'calls order with block' do
    result = CreateOrder.call_block(user, 100)
    order = result.value
    order.total.must_equal 110
  end
end
