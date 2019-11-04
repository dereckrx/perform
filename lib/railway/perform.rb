require 'result'
require 'performer'

module Perform

  module Module
    def perform(*actions, &block)
      default_performer[*actions, &block]
    end

    def success(value = nil)
      Success[value]
    end

    def failure(value)
      Failure[value]
    end

    def successful(action)
      default_performer.successful(action)
    end

    def unwrap(maybe)
      maybe[
        ->(value) {value},
        ->(message) {raise UnwrapError.new(message)}
      ]
    end

    private

    def default_performer
      Performer.new(Success, Failure)
    end
  end
end