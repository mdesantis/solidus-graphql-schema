module Spree::GraphQL::Types::Payment
  include ::Spree::GraphQL::Interfaces::Node

  # Field: amount: The amount of the payment.
  # Args: 
  # Returns: Types::Money, null: false
  def amount()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: billingAddress: The billing address for the payment.
  # Args: 
  # Returns: Types::MailingAddress, null: true
  def billing_address()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkout: The checkout to which the payment belongs.
  # Args: 
  # Returns: Types::Checkout, null: false
  def checkout()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: creditCard: The credit card used for the payment in the case of direct payments.
  # Args: 
  # Returns: Types::CreditCard, null: true
  def credit_card()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: errorMessage: An message describing a processing error during asynchronous processing.
  # Args: 
  # Returns: ::GraphQL::Types::String, null: true
  def error_message()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: id: Globally unique identifier.
  # Args: 
  # Returns: ::GraphQL::Types::ID, null: false
  def id()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: idempotencyKey: A client-side generated token to identify a payment and perform idempotent operations.
  # Args: 
  # Returns: ::GraphQL::Types::String, null: true
  def idempotency_key()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: ready: Whether or not the payment is still processing asynchronously.
  # Args: 
  # Returns: ::GraphQL::Types::Boolean, null: false
  def ready()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: test: A flag to indicate if the payment is to be done in test mode for gateways that support it.
  # Args: 
  # Returns: ::GraphQL::Types::Boolean, null: false
  def test()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: transaction: The actual transaction recorded by Store after having processed the payment with the gateway.
  # Args: 
  # Returns: Types::Transaction, null: true
  def transaction()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

