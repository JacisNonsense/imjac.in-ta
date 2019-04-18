class CreateOnDeckEventPastPerformanceScores < ActiveRecord::Migration[5.2]
  def change
    create_table :on_deck_event_past_performance_scores do |t|
      t.string :team
      t.integer :score

      t.timestamps
    end
    add_index :on_deck_event_past_performance_scores, :team, unique: true
  end
end
