module Dev
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :store_user_location!, if: :storable_location?

    def authenticate_admin!
      unless current_user.try(:admin?)
        sign_out if user_signed_in?
        session["user_return_to"] = request.fullpath
        redirect_to new_user_session_path
      end
    end

    def not_found
      raise ActionController::RoutingError.new('Not Found')
    end

    def after_sign_in_path_for(resource_or_scope)
      stored_location_for(:user) || Proc.new {super}.call # There's a weird bug where || super causes an immediate redirect even if stored_location_for != nil
   end

    def after_sign_out_path_for(resource_or_scope)
      "/dev/maven"
    end

   private
    def storable_location?
      request.get? && !devise_controller? && !request.xhr?
    end

    def store_user_location!
      store_location_for(:user, request.fullpath)
    end
  end
end
