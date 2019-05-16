require_dependency "blog/application_controller"
require 'securerandom'

module Blog
  class EmailSubscriptionsController < ApplicationController
    before_action :find_unsubscribe, only: [:unsubscribe]

    # GET /subscribe
    def new
      @new_subscription = EmailSubscription.new
    end

    # POST /subscribe
    def subscribe
      @email_subscription = EmailSubscription.find_or_initialize_by(email_subscription_params)
      @email_subscription.subscribed = true
      @email_subscription.unsubscribe_token = SecureRandom.uuid

      if !@email_subscription.valid?
        redirect_to subscriptions_notice_path, notice: "Invalid email!"
      elsif @email_subscription.save
        redirect_to subscriptions_notice_path, notice: "You're subscribed!"
      else
        render :new
      end
    end

    # GET /unsubscribe/id
    def unsubscribe
      @sub.subscribed = false
      @sub.save
      redirect_to subscriptions_notice_path, notice: 'You have been unsubscribed!'
    end

    # GET /subscriptions/notice
    def notice_page
    end

    private
      def find_unsubscribe
        @sub = EmailSubscription.find_by(unsubscribe_token: params[:id])
      end

      def email_subscription_params
        params.require(:email_subscription).permit(:email)
      end
  end
end
