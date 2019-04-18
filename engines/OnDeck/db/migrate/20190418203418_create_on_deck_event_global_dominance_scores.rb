class CreateOnDeckEventGlobalDominanceScores < ActiveRecord::Migration[5.2]
  def change
    create_table :on_deck_event_global_dominance_scores do |t|
      t.string :team
      t.integer :score
      t.integer :rank

      t.timestamps
    end
    add_index :on_deck_event_global_dominance_scores, :team, unique: true
  end
end
