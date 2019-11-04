class User
  attr_reader :region, :active

  def initialize(region, active)
    @region = region
    @active = active
  end

end