class Spree::GraphQL::Schema::Payloads::CheckoutGiftCardsAppend < Spree::GraphQL::Schema::Types::BaseObject
  graphql_name 'CheckoutGiftCardsAppendPayload'
  description nil
  include ::Spree::GraphQL::Payloads::CheckoutGiftCardsAppend

  field :checkout, ::Spree::GraphQL::Schema::Types::Checkout, null: true do
    description %q{The updated checkout object.}
  end
  field :user_errors, [::Spree::GraphQL::Schema::Types::UserError], null: false do
    description %q{List of errors that occurred executing the mutation.}
  end
end
