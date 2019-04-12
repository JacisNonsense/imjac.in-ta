module Dev
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :store_user_location!, if: :storable_location?
    before_action :configure_permitted_parameters, if: :devise_controller?

    def authenticate_admin!
      unless current_user.try(:admin?)
        sign_out if user_signed_in?
        session["user_return_to"] = request.fullpath
        redirect_to new_user_session_path
      end
    end

    def deploy_token_owner token_id
      token_id.nil? ? nil : DeployToken.find_by(token: token_id)&.user
    end

    def configure_permitted_parameters
      added_attrs = [:username, :email, :password, :password_confirmation, :remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :account_update, keys: (added_attrs - [:username])
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
