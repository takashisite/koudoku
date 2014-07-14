module Koudoku::Checkout
  extend ActiveSupport::Concern

  included do

    attr_accessor :credit_card_token

    belongs_to :video

    before_save :processing!

    def processing!

      if owner_stripe_id.present?

        begin
          charge = Stripe::Charge.create(
          :amount => (self.price*Koudoku.stripe_amount).to_i,
          :currency => Koudoku.stripe_currency,
          :customer => owner_stripe_id
          )
          self.stripe_charge_id = charge.id
        rescue Stripe::CardError => e
          return false;
        end

      else
        return false

      end

    end

  end

  # Pretty sure this wouldn't conflict with anything someone would put in their model
  def subscription_owner
    # Return whatever we belong to.
    # If this object doesn't respond to 'name', please update owner_description.
    send Koudoku.subscriptions_owned_by
  end

  def owner_stripe_id
    subscription_owner.subscription.stripe_id
  end

end
