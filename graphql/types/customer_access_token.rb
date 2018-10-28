module Spree::GraphQL::Types::CustomerAccessToken


  # Field: accessToken: The customer’s access token.
  # Args: 
  # Returns: ::GraphQL::Types::String, null: false
  def access_token()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: expiresAt: The date and time when the customer access token expires.
  # Args: 
  # Returns: Types::DateTime, null: false
  def expires_at()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

