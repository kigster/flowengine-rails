# frozen_string_literal: true

module FlowEngine
  class FlowSession < ApplicationRecord
    self.table_name = "flow_engine_sessions"

    belongs_to :flow_definition, foreign_key: :definition_id, inverse_of: :flow_sessions

    validates :status, presence: true, inclusion: { in: %w[in_progress completed abandoned] }

    scope :in_progress, -> { where(status: "in_progress") }
    scope :completed, -> { where(status: "completed") }
    scope :abandoned, -> { where(status: "abandoned") }

    def engine
      state = {
        current_step_id: current_step_id,
        answers: answers || {},
        history: history || []
      }
      FlowEngine::Engine.from_state(flow_definition.parsed_definition, state)
    end

    def advance!(answer_value)
      eng = engine
      eng.answer(answer_value)
      persist_engine_state!(eng)
    end

    def abandon!
      update!(status: "abandoned")
    end

    def in_progress?
      status == "in_progress"
    end

    def completed?
      status == "completed"
    end

    def abandoned?
      status == "abandoned"
    end

    def finished?
      completed? || abandoned?
    end

    def current_node
      return nil if current_step_id.blank?

      flow_definition.parsed_definition.step(current_step_id.to_sym)
    rescue FlowEngine::UnknownStepError
      nil
    end

    def progress_percentage
      total = flow_definition.total_steps
      return 0 if total.zero?

      completed_count = (history || []).size
      [(completed_count.to_f / total * 100).round, 100].min
    end

    def result_json
      {
        definition_name: flow_definition.name,
        definition_version: flow_definition.version,
        answers: answers,
        history: history,
        status: status,
        completed_at: updated_at&.iso8601
      }
    end

    private

    def persist_engine_state!(eng)
      state = eng.to_state
      new_status = eng.finished? ? "completed" : "in_progress"

      update!(
        current_step_id: state[:current_step_id]&.to_s,
        answers: state[:answers].transform_keys(&:to_s),
        history: state[:history].map(&:to_s),
        status: new_status
      )

      fire_completion_callback if new_status == "completed"
    end

    def fire_completion_callback
      callback = FlowEngine::Rails.configuration.on_session_complete
      callback&.call(self)
    end
  end
end
