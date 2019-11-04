class Order

  attr_accessor :tax
  attr_reader :total, :free_shipping, :region, :total_with_tax

  def initialize(region: 'USA', total: 100, tax: 0, send_notification: false, order_submitted: false)
    @region = region
    @free_shipping = false
    @tax = tax
    @total = total
    @send_notification = send_notification
    @order_submitted = order_submitted
  end

  def provide_free_shipping!
    @free_shipping = true
  end

  def send_notification?
    @send_notification
  end

  def submit_order_successful?
    @order_submitted
  end

  def total_with_tax
    total + tax
  end
end