module Spree::GraphQL::Types::Domain
  # @graphql host The host name of the domain (eg: `example.com`).
  # @return [Types::String!]
  def host()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # @graphql sslEnabled Whether SSL is enabled or not.
  # @return [Types::Boolean!]
  def ssl_enabled()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # @graphql url The URL of the domain (eg: `https://example.com`).
  # @return [Types::URL!]
  def url()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

