require 'perform/result'

module Perform

  class Performer
    attr_reader :success_class, :failure_class

    def initialize(success_class, failure_class)
      @success_class = success_class
      @failure_class = failure_class
    end

    def call(*actions, &block)
      if actions.empty?
        do_call(&block)
      else
        result = reduce(*actions)
        result.has_key?(:error) ?
          failure(result) :
          success(result)
      end
    end
    alias_method :[], :call

    # TODO: test
    def do_call
      wrap_if_value(yield)
    rescue UnwrapError => error
      failure(error.message)
    end

    def successful(action)
      ->(*args) { success(action.call(*args)) }
    end

    private

    def reduce(initial_context, *func_defs)
      func_defs.reduce(initial_context) do |ctx, (func, signature)|
        return ctx if ctx[:error]

        if signature
          param_keys, return_key = signature.is_a?(Array) ?
              [signature, nil] :
              signature.to_a.first
        else
          param_keys, return_key = [[], nil]
        end

        result = param_keys.empty? ?
          func.call :
          func.call(ctx.slice(*param_keys))

        if return_key.nil?
          next either(result,
            ->(_) {ctx},
            ->(error) {ctx.merge(error: error)}
          )
        end

        if result.nil? || !is_result(result)
          return ctx.merge(error: missing_return_value_error(func, return_key, result))
        end

        either(result,
          ->(value) {ctx.merge(return_key => value)},
          ->(error) {ctx.merge(error: error)}
        )
      end
    end

    def missing_return_value_error(func, return_key, value)
      params = func.method(:call).parameters.empty? ? '()' : "(#{func.parameters.join(',')})"
      name = func.class == Proc ? func.class.name : func.name
      value_str = value || "'nil'"
      ResultError.new("#{name}.call#{params} returned #{value_str} instead of a Result for '#{return_key}'")
    end

    def either(result, success_handler, failure_handler)
      if result.success?
        success_handler.call(fetch_value(result))
      else
        failure_handler.call(fetch_error(result))
      end
    end

    def success(value)
      success_class.new(value)
    end

    def failure(value)
      failure_class.new(value)
    end

    def wrap_if_value(value)
      is_result(value) ?
        value :
        success(value)
    end

    def is_result(result)
      result.respond_to?(:success?)
    end

    def fetch_value(success)
      if success.respond_to?(:value)
        success.value
      elsif success.respond_to?(:value!)
        success.value!
      else
        raise RuntimeError.new("Unsupported Success type #{success}")
      end
    end

    def fetch_error(failure)
      if failure.respond_to?(:error)
        failure.error
      elsif failure.respond_to?(:failure)
        failure.failure
      elsif failure.respond_to?(:value)
        failure.value
      else
        raise RuntimeError.new("Unsupported Failure type #{failure}")
      end
    end

    class ResultError < ArgumentError

    end

    class UnwrapError < StandardError
      attr_reader :message

      def initialize(message)
        super
        @message = message
      end
    end
  end
end