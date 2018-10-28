module Spree::GraphQL::Payloads::CheckoutCreate


  # Field: checkout: The new checkout object.
  # Args: 
  # Returns: Types::Checkout, null: true
  def checkout()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: checkoutUserErrors: List of errors that occurred executing the mutation.
  # Args: 
  # Returns: [Types::CheckoutUserError], null: false
  def checkout_user_errors()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

