# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/spec/dummy/"
  enable_coverage :branch
  minimum_coverage 90
end

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"

require "rspec/rails"
require "rspec/its"

# Run migrations in memory
ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do
    create_table :flow_engine_definitions, force: true do |t|
      t.string :name, null: false
      t.integer :version, null: false, default: 1
      t.text :dsl, null: false
      t.boolean :active, null: false, default: false
      t.timestamps
    end

    add_index :flow_engine_definitions, %i[name version], unique: true

    create_table :flow_engine_sessions, force: true do |t|
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

SIMPLE_DSL = <<~RUBY
  FlowEngine.define do
    start :step1

    step :step1 do
      type :multi_select
      question "Pick options"
      options %w[A B C]
      transition to: :step2, if_rule: contains(:step1, "B")
    end

    step :step2 do
      type :text
      question "You picked B"
    end
  end
RUBY

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.use_transactional_fixtures = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    FlowEngine::Rails::DslLoader.clear_cache!
    FlowEngine::Rails.reset_configuration!
  end
end
