module Koudoku
  class CheckoutsController < ApplicationController
    before_filter :load_owner
    before_filter :load_subscription

    def unauthorized
      render status: 401, template: "koudoku/subscriptions/unauthorized"
      false
    end

    def load_owner
      unless params[:owner_id].nil?
        if current_owner.present?

          searched_owner = current_owner.class.find(params[:owner_id]) rescue nil

          if searched_owner.nil? && current_owner.class.respond_to?(:friendly)
            searched_owner = current_owner.class.friendly.find(params[:owner_id]) rescue nil
          end

          if current_owner.try(:id) == searched_owner.try(:id)
            @owner = current_owner
          else
            return unauthorized
          end
        else
          return unauthorized
        end
      end
    end

    def no_owner?
      @owner.nil?
    end

    def load_subscription
      ownership_attribute = (Koudoku.subscriptions_owned_by.to_s + "_id").to_sym
      @subscription = ::Subscription.where(ownership_attribute => current_owner.id).find_by_id(current_owner.id)
      return @subscription.present? ? @subscription : unauthorized
    end

    # the following two methods allow us to show the pricing table before someone has an account.
    # by default these support devise, but they can be overriden to support others.
    def current_owner
      # e.g. "self.current_user"
      send "current_#{Koudoku.subscriptions_owned_by.to_s}"
    end

    def redirect_to_sign_up
      session["#{Koudoku.subscriptions_orewned_by.to_s}_return_to"] = new_subscription_path(plan: params[:plan])
      redirect_to new_registration_path(Koudoku.subscriptions_owned_by.to_s)
    end

    def create
      if no_owner?

        # stripe_checkout_params = {'stripe_id' => @subscription.stripe_id, 'video_id' =>checkout_params['video_id']}

        stripe_checkout_params = Hash::new
        stripe_checkout_params = checkout_params
        stripe_checkout_params[Koudoku.checkouts_items_is.to_s+'_id'] = checkout_params['item_id']
        stripe_checkout_params['stripe_id'] = @subscription.stripe_id

        logger.debug(stripe_checkout_params.inspect)
        logger.debug(@owner)

        # @checkout = ::Checkout.new(checkout_params)
        # @checkout.user = @owner
        # if @checkout.save
        #   flash[:notice] = "You've been successfully upgraded."
        #   redirect_to owner_checkout_path(@owner, @checkout)
        # else
        #   flash[:error] = 'There was a problem processing this transaction.'
        #   render :new
        # end

      end

    end

    private
    def checkout_params
      # If strong_parameters is around, use that.
      if defined?(ActionController::StrongParameters)
        params.require(:checkout).permit(:item_id, :stripe_id, :price, :credit_card_token, :card_type, :last_four)
      else
        # Otherwise, let's hope they're using attr_accessible to protect their models!
        params[:subscription]
      end
    end

  end
end
