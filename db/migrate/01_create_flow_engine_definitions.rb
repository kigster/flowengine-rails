# frozen_string_literal: true

class CreateFlowEngineDefinitions < ActiveRecord::Migration[8.0]
  def change
    create_table :flow_engine_definitions do |t|
      t.string :name, null: false
      t.integer :version, null: false, default: 1
      t.text :dsl, null: false
      t.boolean :active, null: false, default: false

      t.timestamps
    end

    add_index :flow_engine_definitions, %i[name version], unique: true
    add_index :flow_engine_definitions, :name, unique: true, where: "active = 1",
                                               name: "index_flow_engine_definitions_on_name_active"
  end
end
