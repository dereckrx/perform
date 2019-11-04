require 'tax_range'
require 'perform/result'
require 'perform/perform'

class CalculatesTax
  extend Perform::Module

  def self.call(order)
    perform(
      {order: order},
      [LooksUpTaxPercentageAction, [:order] => :tax_percentage],
      [successful(CalculatesOrderTaxAction), [:order, :tax_percentage]],
      [ProvidesFreeShippingAction, [:order] => :order]
    )
  end
end

class CalculatesTaxDo
  include Perform

  def call(order)
    perform do
      tax_percentage = unwrap LooksUpTaxPercentageAction(order)
      CalculatesOrderTaxAction.call(order: order, tax_percentage: tax_percentage)
      ProvidesFreeShippingAction.call(order)
    end
  end
end

class LooksUpTaxPercentageAction
  # Works with custom Result classes
  class Success
    def initialize(value); @value = value; end
    def value; @value; end
    def success?; true; end
  end

  class Failure
    def initialize(value); @value = value; end
    def error; @value; end
    def success?; false; end
  end

  def self.call(order:)
    tax_ranges = TaxRange.for_region(order.region)

    return Failure.new('The tax ranges were not found') if tax_ranges.nil?

    tax_percentage = tax_ranges.for_total(order.total)

    return Failure.new('The tax percentage was not found') if tax_percentage.nil?
    return Success.new(tax_percentage)
  end
end

# Works with non-wrapped functions
class CalculatesOrderTaxAction
  def self.call(order:, tax_percentage:)
    (order.total * (tax_percentage / 100)).round(2)
  end
end

class ProvidesFreeShippingAction
  extend Perform::Module

  def self.call(order:)
    if order.total_with_tax > 200
      order.provide_free_shipping!
    end
    success(order)
  end
end