module Koudoku
  class WebhooksController < ApplicationController

    skip_before_filter :verify_authenticity_token


    def create

      raise "API key not configured. For security reasons you must configure this in 'config/koudoku.rb'." unless Koudoku.webhooks_api_key.present?
      raise "Invalid API key. Be sure the webhooks URL Stripe is configured with includes ?api_key= and the correct key." unless params[:api_key] == Koudoku.webhooks_api_key

      data_json = JSON.parse request.body.read

      if data_json['type'] == "invoice.payment_succeeded"

        stripe_id = data_json['data']['object']['customer']
        amount = data_json['data']['object']['total'].to_f / 100.0
        subscription = ::Subscription.find_by_stripe_id(stripe_id)
        subscription.payment_succeeded(amount)

      elsif data_json['type'] == "charge.failed"

        stripe_id = data_json['data']['object']['customer']

        subscription = ::Subscription.find_by_stripe_id(stripe_id)
        subscription.charge_failed

      elsif data_json['type'] == "charge.dispute.created"

        stripe_id = data_json['data']['object']['customer']

        subscription = ::Subscription.find_by_stripe_id(stripe_id)
        subscription.charge_disputed

      elsif data_json['type'] == "charge.succeeded"
        stripe_id = data_json['data']['object']['customer']
        stripe_charge_id = data_json['data']['object']['id']
        

      end

      render nothing: true

    end

  end
end
