class CreateOnDeckUpcomingRecommendations < ActiveRecord::Migration[5.2]
  def change
    create_table :on_deck_upcoming_recommendations do |t|
      t.string :data

      t.timestamps
    end
  end
end
