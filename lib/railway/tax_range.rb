class TaxRange
  def self.for_region(region)
    if region == 'USA'
      new(region)
    else
      nil
    end
  end

  def initialize(region)
    @region = region
  end

  def for_total(total)
    total > 1000 ? nil : 10.0
  end
end