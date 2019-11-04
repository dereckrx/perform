require 'tax_range'
require 'perform'

class CalculateTax
  extend Perform::Module

  LookupTaxRange = ->(order:) {
    tax_range = TaxRange.for_region(order.region)
    tax_range ?
      success(tax_range) :
      failure('The tax ranges were not found')
  }

  TaxPercentageForTotal = ->(order:, tax_range:) {
    tax_percentage = tax_range.for_total(order.total)
    tax_percentage.nil? ?
      failure('The tax percentage was not found') :
      success(tax_percentage)
  }

  CalculateTaxForOrder = ->(order:, tax_percentage:) {
    order.tax = (order.total * (tax_percentage / 100.0)).round(2)
    success(order)
  }

  CheckFreeShipping = ->(order:) {
    if order.total_with_tax > 200
      order.provide_free_shipping!
    end
    success(order)
  }

  def self.call(order)
    result = perform(
      {order: order},
      [LookupTaxRange, [:order] => :tax_range],
      [TaxPercentageForTotal, [:order, :tax_range] => :tax_percentage],
      [CalculateTaxForOrder, [:order, :tax_percentage] => :order],
      [CheckFreeShipping, [:order] => :order]
    )
    result.success? ?
      {order: result.value[:order]} :
      {error: result.value[:error]}
  end
end