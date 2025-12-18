class AllowNullPlayer2InGameStates < ActiveRecord::Migration[8.0]
  def change
    change_column_null :game_states, :player2_id, true
  end
end
