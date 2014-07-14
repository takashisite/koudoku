module Koudoku
  class CheckoutsController < ApplicationController
    before_filter :load_owner
    before_filter :load_subscription

    def unauthorized
      render status: 401, template: "koudoku/subscriptions/unauthorized"
      false
    end

    def load_owner
      if current_owner.present?
          @owner = current_owner
      else
        return unauthorized
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

    def new
      @checkout = Checkout.new
    end

    def edit
      logger.debug(checkout_params)
      stripe_checkout_params = Hash::new
      stripe_checkout_params = checkout_params
      stripe_checkout_params[Koudoku.checkouts_items_is.to_s+'_id'] = checkout_params['item_id']
      # stripe_checkout_params['stripe_id'] = @subscription.stripe_id
      stripe_checkout_params.delete('item_id')

      @checkout = ::Checkout.new(stripe_checkout_params)
      return
    end


    def create
      session["#{Koudoku.subscriptions_owned_by.to_s}_return_to"] = request.referrer

      if (@subscription.last_four.blank? && checkout_params['last_four'].blank?)
        params.delete('authenticity_token')
        redirect_to edit_checkout_path(@owner, params)

      elsif (@subscription.last_four.blank? && checkout_params['last_four'].present?)
        checkout_subscription_params = Hash::new
        checkout_subscription_params = checkout_params
        checkout_subscription_params.delete("credit_card_token")
        checkout_subscription_params.delete("card_type")
        checkout_subscription_params.delete("last_four")
        card_subscription_params = Hash::new
        card_subscription_params = checkout_params
        card_subscription_params.delete("item_id")
        card_subscription_params.delete(Koudoku.checkouts_items_is.to_s+'_id')
        card_subscription_params.delete('price')

        if @subscription.update_attributes(card_subscription_params)
          @checkout = ::Checkout.new(checkout_subscription_params)
          @checkout.user = @owner
          if @checkout.save
            flash[:notice] = "You've been successfully charged."
            redirect_to session["#{Koudoku.subscriptions_owned_by.to_s}_return_to"]
            # redirect_to owner_checkout_path(@owner, @checkout)
          else
            flash[:error] = 'There was a problem processing this transaction.'
            render :edit
          end

        else
          flash[:error] = 'There was a problem processing this transaction.'
          render :edit
        end

      else
        stripe_checkout_params = Hash::new
        stripe_checkout_params = checkout_params
        stripe_checkout_params[Koudoku.checkouts_items_is.to_s+'_id'] = checkout_params['item_id']
        # stripe_checkout_params['stripe_id'] = @subscription.stripe_id
        stripe_checkout_params.delete('item_id')

        @checkout = ::Checkout.new(stripe_checkout_params)
        @checkout.user = @owner
        if @checkout.save
          flash[:notice] = "You've been successfully charged."
          redirect_to session["#{Koudoku.subscriptions_owned_by.to_s}_return_to"]
          # redirect_to owner_checkout_path(@owner, @checkout)
        else
          flash[:error] = 'There was a problem processing this transaction.'
          render :edit
        end
      end

    end



    private
    def checkout_params
      # If strong_parameters is around, use that.
      if defined?(ActionController::StrongParameters)
        params.require(:checkout).permit(:item_id, :stripe_id, :price, :credit_card_token, :card_type, :last_four, eval(":#{Koudoku.checkouts_items_is}_id"))
      else
        # Otherwise, let's hope they're using attr_accessible to protect their models!
        params[:subscription]
      end
    end

  end
end
