class DropGlobalScores < ActiveRecord::Migration[5.0]
  def change
    drop_table :global_scores
  end
end
