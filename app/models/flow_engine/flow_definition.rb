# frozen_string_literal: true

module FlowEngine
  class FlowDefinition < ApplicationRecord
    self.table_name = "flow_engine_definitions"

    has_many :flow_sessions, dependent: :restrict_with_error, foreign_key: :definition_id, inverse_of: :flow_definition

    validates :name, presence: true
    validates :version, presence: true,
                        numericality: { only_integer: true, greater_than: 0 },
                        uniqueness: { scope: :name }
    validates :dsl, presence: true
    validate :dsl_must_parse

    attr_accessor :skip_auto_version

    before_validation :auto_increment_version, on: :create, unless: :skip_auto_version

    scope :active, -> { where(active: true) }
    scope :by_name, ->(name) { where(name: name) }
    scope :latest_version, ->(name) { by_name(name).order(version: :desc).first }

    def parsed_definition
      @parsed_definition ||= FlowEngine::Rails::DslLoader.load(dsl, cache_key: cache_key_for_dsl)
    end

    def activate!
      transaction do
        self.class.where(name: name, active: true).where.not(id: id).update_all(active: false)
        update!(active: true)
      end
    end

    def deactivate!
      update!(active: false)
    end

    def readonly?
      flow_sessions.exists? && persisted? && !new_record?
    end

    def mermaid_diagram
      exporter = FlowEngine::Graph::MermaidExporter.new(parsed_definition)
      exporter.export
    end

    def step_ids
      parsed_definition.step_ids
    end

    def total_steps
      step_ids.size
    end

    private

    def cache_key_for_dsl
      "definition:#{id}:v#{version}" if persisted?
    end

    def auto_increment_version
      max_version = self.class.where(name: name).maximum(:version) || 0
      self.version = max_version + 1
    end

    def dsl_must_parse
      return if dsl.blank?

      FlowEngine::Rails::DslLoader.load(dsl)
    rescue FlowEngine::Error => e
      errors.add(:dsl, "is invalid: #{e.message}")
    end
  end
end
