require 'order'
require 'railway'
require 'perform/result'

class CreateOrder
  extend Perform::Module

  VerifyActiveUser = ->(user:) {
    user.active ? success(user) : failure('User not active')
  }

  CalculateTotal = ->(subtotal:) {
    success(subtotal + 10)
  }

  CreateOrderRecord = ->(user:, total:) {
    success(Order.new(region: user.region, total: total))
  }

  PayForOrder = ->(user:, order:) {
    success(order)
  }

  SendConfirmationEmail = ->(user:, order:) {
    success(order)
  }

  def self.call(user, subtotal)
    perform(
      {user: user, subtotal: subtotal},
      [VerifyActiveUser, [:user]],
      [CalculateTotal, [:subtotal] => :total],
      [CreateOrderRecord, [:user, :total] => :order],
      [PayForOrder, [:user, :order]],
      [SendConfirmationEmail, [:user, :order]]
    )
  end

  def self.call_block(user, subtotal)
    perform do
      unwrap VerifyActiveUser.call(user: user)
      total = unwrap CalculateTotal.call(subtotal: subtotal)
      order = unwrap CreateOrderRecord.call(user: user, total: total)
      unwrap PayForOrder.call(user: user, order: order)
      unwrap SendConfirmationEmail.call(user: user, order: order)
    end
  end

  # Alternative way using a DSL
  # def self.call2(user, subtotal)
  #   perform
  #     .with(user: user, subtotal: subtotal)
  #     .then(VerifyActiveUser, :user)
  #     .then(CalculateTotal, :subtotal).returns(:total)
  #     .then(CreateOrderRecord, :user, :total).returns(:order)
  #     .then(PayForOrder, :user, :order)
  #     .then(SendConfirmationEmail, :user, :order)
  #     .then(SendConfirmationEmail, :user, :order).returns(:user)
  #     .call
  # end
end