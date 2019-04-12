module Dev
  class DeployToken < ApplicationRecord
    belongs_to :user, foreign_key: :dev_user_id
  end
end
