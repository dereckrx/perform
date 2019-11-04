require 'light-service'

# GOOD
class CalculatesTax
  extend LightService::Organizer

  def self.call(order)
    with(:order => order).reduce(
      LooksUpTaxPercentageAction,
      CalculatesOrderTaxAction,
      ProvidesFreeShippingAction
    )
  end
end

class LooksUpTaxPercentageAction
  extend LightService::Action
  expects :order
  promises :tax_percentage

  executed do |context|
    tax_ranges = TaxRange.for_region(context.order.region)
    context.tax_percentage = 0

    next context if object_is_nil?(tax_ranges, context, 'The tax ranges were not found')

    context.tax_percentage = tax_ranges.for_total(context.order.total)

    next context if object_is_nil?(context.tax_percentage, context, 'The tax percentage was not found')
  end

  def self.object_is_nil?(object, context, message)
    if object.nil?
      context.fail!(message)
      return true
    end

    false
  end
end

class CalculatesOrderTaxAction
  extend ::LightService::Action
  expects :order, :tax_percentage

  # I am using ctx as an abbreviation for context
  executed do |ctx|
    order = ctx.order
    order.tax = (order.total * (ctx.tax_percentage/100)).round(2)
  end

end

class ProvidesFreeShippingAction
  extend LightService::Action
  expects :order

  executed do |ctx|
    if ctx.order.total_with_tax > 200
      ctx.order.provide_free_shipping!
    end
  end
end

class SubmitsOrderAction
  extend LightService::Action
  expects :order, :mailer

  executed do |context|
    unless context.order.submit_order_successful?
      context.fail_and_return!("Failed to submit the order")
    end

    # This won't be executed
    context.mailer.send_order_notification!
  end
end

class ChecksOrderStatusAction
  extend LightService::Action
  expects :order

  executed do |context|
    if context.order.send_notification?
      context.skip_remaining!("Everything is good, no need to execute the rest of the actions")
    end
  end
end