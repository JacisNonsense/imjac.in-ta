module Dev
  class RegistrationsController < Devise::RegistrationsController
    before_action :check_one_user?, only: [:new, :create]

    protected

    # On this website, we only want the admin user.
    def check_one_user?
      if User.count >= 1
        if user_signed_in?
          redirect_to root_path
        else
          redirect_to new_user_session_path
        end
      end
    end
  end
end