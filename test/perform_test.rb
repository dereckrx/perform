require 'minitest/autorun'
require 'test_helper'
require 'perform/perform'

describe Perform do
  include Perform::Module

  it 'stores empty context' do
    result = perform({})
    result.success?.must_equal true
    result.value.must_equal({})
  end

  it 'stores initial context' do
    result = perform({a: 1})
    result.success?.must_equal true
    result.value[:a].must_equal 1
  end

  it 'fails with error' do
    result = perform(
      {a: 1},
      [->() {failure('always fail')}]
    )
    result.success?.must_equal false
    result.value[:error].must_equal 'always fail'
  end

  it 'sets promised value' do
    result = perform(
      {},
      [->() {success(1)}, [] => :a]
    )
    result.success?.must_equal true
    result.value.must_equal({a: 1})
  end

  it 'expects value and sets promised value in the context' do
    result = perform(
      {a: 1},
      [->(a:) {success(a + 1)}, [:a] => :b]
    )
    result.success?.must_equal true
    result.value.must_equal({a: 1, b: 2})
  end

  it 'fails if action fails even if action has no return key' do
    result = perform(
      {},
      [->() {failure}]
    )
    result.success?.must_equal false
  end

  describe 'errors' do

    it 'errors if missing promised return key for class' do
      class MissingReturnValueClass
        def self.call;
          nil;
        end
      end

      result = perform(
        {},
        [MissingReturnValueClass, [] => :b]
      )
      result.value[:error].message.must_equal "MissingReturnValueClass.call() returned 'nil' instead of a Result for 'b'"
    end

    it 'errors if missing promised return key for proc' do
      MissingReturnValueProc = ->() {nil}

      result = perform(
        {},
        [MissingReturnValueProc, [] => :b]
      )
      result.value[:error].message.must_equal "Proc.call() returned 'nil' instead of a Result for 'b'"
    end

    it 'errors if missing promised return key with parameters in message' do
      MissingReturnValue = ->(a:) {nil}

      result = perform(
        {a: {}},
        [MissingReturnValue, [:a] => :b],
      )
      result.value[:error].message.must_equal "Proc.call(keyreq,a) returned 'nil' instead of a Result for 'b'"
    end
  end
end
