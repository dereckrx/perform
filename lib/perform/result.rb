module Perform
  class Result
    attr_reader :value

    def self.[](value)
      new(value)
    end

    def initialize(value)
      @value = value
    end

    def success?
      false
    end
  end

  class Success < Result
    def success?
      true
    end

    def [](handle_success, _)
      handle_success.call(value)
    end
  end

  class Failure < Result
    def [](_, handle_failure)
      handle_failure.call(value)
    end
  end
end