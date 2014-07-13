module Koudoku::Checkout
  extend ActiveSupport::Concern

  included do

    attr_accessor :credit_card_token

    belongs_to :video

    before_save :processing!

    def processing!

      if stripe_id.present?

        begin
          charge = Stripe::Charge.create(
          :amount => self.price,
          :currency => "usd",
          :customer => self.stripe_id
          )
        rescue Stripe::CardError => e

        end

      else
        logger.degub("===========================no stripe id")

      end

    end

  end

end
