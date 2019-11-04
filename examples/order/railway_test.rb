require 'minitest/autorun'
require 'railway'
require 'order'
require 'perform/performer'

describe Perform do
  include Perform::Module

  let(:order) {Order.new(region: 'USA')}

  it 'returns value' do
    result = CalculatesTax.call(order)
    result.value[:order].tax.must_equal 0
    result.value[:order].free_shipping.must_equal false
    result.value[:tax_percentage].must_equal 10
  end

  it 'contains failure message' do
    order = Order.new(region: 'China')
    result = CalculatesTax.call(order)
    result.value[:error].must_equal 'The tax ranges were not found'
    result.value[:order].tax.must_equal 0
  end

  it 'fails and returns without executing following actions' do
    order = Order.new(region: 'China')
    result = CalculatesTax.call(order)
    result.value[:order].tax.must_equal 0
  end

  class SubmitsOrderAction
    extend Perform::Module

    def self.call(order:, mailer:)
      unless order.submit_order_successful?
        return failure('Failed to submit the order')
      end

      # This won't be executed
      mailer.sent_mail = 1
      success
    end
  end

  it 'allows failing early' do
    mailer = Struct.new(:sent_mail).new(0)
    result = perform(
      {order: order, mailer: mailer},
      [SubmitsOrderAction, [:order, :mailer]]
    )
    mailer.sent_mail.must_equal 0
    result.success?.must_equal false
    result.value[:error].must_equal 'Failed to submit the order'
  end

  class ChecksOrderStatusAction
    extend Perform::Module

    def self.call(order:)
      if order.send_notification?
        # Everything is good, no need to execute the rest of the actions
        success
      else
        # Use new perform instead of trying to bail out of the calling perform
        perform(
          {order: order},
          # some other actions...
        )
      end
    end
  end

  it 'how to handle skipping remaining' do
    result = perform(
      {order: order},
      [ChecksOrderStatusAction, [:order]]
    )
    result.success?.must_equal true
  end

  describe 'action' do

    it 'errors if missing expected param' do
      assert_raises(ArgumentError) do
        CalculatesOrderTaxAction.call(order: order)
      end.message.must_equal 'missing keyword: tax_percentage'
    end
  end
end