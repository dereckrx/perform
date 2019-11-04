require 'minitest/autorun'
require 'light-service'
require_relative './example'

describe 'light-service' do

  let(:order) { Order.new('USA') }

  it 'returns success' do
    context = CalculatesTax.call(order)
    context.success?.must_equal true
    context.message.must_equal ''
  end

  it 'returns value' do
    context = CalculatesTax.call(order)
    context.order.tax.must_equal 0
    context.order.free_shipping.must_equal false
    context.tax_percentage.must_equal 10
  end

  it 'contains failure message' do
    order = Order.new('China')
    context = CalculatesTax.call(order)
    context.message.must_equal 'The tax ranges were not found'
    context.order.tax.must_equal 0
  end

  it 'fails and returns without executing following actions' do
    order = Order.new('China')
    context = CalculatesTax.call(order)
    context.order.tax.must_equal 0
  end

  describe 'action' do

    it 'errors if missing expected param' do
      assert_raises(LightService::ExpectedKeysNotInContextError) do
        LooksUpTaxPercentageAction.execute
      end
    end

    it 'errors if missing promised return key' do
      class NoReturnKey
        extend LightService::Action
        promises :tax_percentage
        executed { |context| }
      end

      assert_raises(LightService::PromisedKeysNotInContextError) do
        NoReturnKey.execute
      end
    end


  end

end