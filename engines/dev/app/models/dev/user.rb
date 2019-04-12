module Dev
  class User < ApplicationRecord
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable
    
    before_save :promote_admin

   private
    # Promote the first registered user to admin-status
    def promote_admin
      self.admin = true if User.count == 0
    end
  end
end
