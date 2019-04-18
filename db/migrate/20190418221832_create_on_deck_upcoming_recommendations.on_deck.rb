# This migration comes from on_deck (originally 20190418221320)
class CreateOnDeckUpcomingRecommendations < ActiveRecord::Migration[5.2]
  def change
    create_table :on_deck_upcoming_recommendations do |t|
      t.string :data

      t.timestamps
    end
  end
end
