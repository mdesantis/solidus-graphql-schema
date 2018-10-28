module Spree::GraphQL::Types::PaymentSettings


  # Field: acceptedCardBrands: List of the card brands which the shop accepts.
  # Args: 
  # Returns: [Types::CardBrand], null: false
  def accepted_card_brands()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: cardVaultUrl: The url pointing to the endpoint to vault credit cards.
  # Args: 
  # Returns: Types::URL, null: false
  def card_vault_url()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: countryCode: The country where the shop is located.
  # Args: 
  # Returns: Types::CountryCode, null: false
  def country_code()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: currencyCode: The three-letter code for the currency that the shop accepts.
  # Args: 
  # Returns: Types::CurrencyCode, null: false
  def currency_code()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: storePaymentsAccountId: The shop’s Store Payments account id.
  # Args: 
  # Returns: ::GraphQL::Types::String, null: true
  def store_payments_account_id()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

  # Field: supportedDigitalWallets: List of the digital wallets which the shop supports.
  # Args: 
  # Returns: [Types::DigitalWallet], null: false
  def supported_digital_wallets()
    raise ::Spree::GraphQL::NotImplementedError.new
  end

end

