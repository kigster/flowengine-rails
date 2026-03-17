# frozen_string_literal: true

class CreateFlowEngineSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :flow_engine_sessions do |t|
      t.references :definition, null: false, foreign_key: { to_table: :flow_engine_definitions }
      t.string :current_step_id
      t.json :answers, default: {}
      t.json :history, default: []
      t.string :status, null: false, default: "in_progress"
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :flow_engine_sessions, :status
  end
end
