# BAD
# Too many responsibilities

require 'tax_range'

class CalculateTax
  def self.call(order)
    tax_ranges = TaxRange.for_region(order.region)

    if tax_ranges.nil?
      return {:error => "The tax ranges were not found"}
    end

    tax_percentage = tax_ranges.for_total(order.total)

    if tax_percentage.nil?
      return {:error => "The tax percentage was not found"}
    end

    order.tax = (order.total * (tax_percentage/100.0)).round(2)

    if order.total_with_tax > 200
      order.provide_free_shipping!
    end
    return {order: order}
  end
end