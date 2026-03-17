# frozen_string_literal: true

module FlowEngine
  class SessionsController < ApplicationController
    before_action :set_session, only: %i[show update completed abandon]

    def new
      @definitions = FlowEngine::FlowDefinition.active.order(:name)
      @definition_id = params[:definition_id]
    end

    def create
      definition = FlowEngine::FlowDefinition.find(params[:definition_id])
      engine = FlowEngine::Engine.new(definition.parsed_definition)
      state = engine.to_state

      session = FlowEngine::FlowSession.create!(
        flow_definition: definition,
        current_step_id: state[:current_step_id]&.to_s,
        answers: {},
        history: state[:history].map(&:to_s),
        status: "in_progress"
      )

      redirect_to session_path(session, embed_params)
    end

    def show
      if @flow_session.completed?
        redirect_to completed_session_path(@flow_session, embed_params)
        return
      end

      @node = @flow_session.current_node
      @progress = @flow_session.progress_percentage
    end

    def update
      unless @flow_session.in_progress?
        redirect_to session_path(@flow_session, embed_params)
        return
      end

      answer_value = parse_answer
      @flow_session.advance!(answer_value)

      if @flow_session.completed?
        redirect_to completed_session_path(@flow_session, embed_params)
      else
        redirect_to session_path(@flow_session, embed_params)
      end
    end

    def completed
      @result = @flow_session.result_json
    end

    def abandon
      @flow_session.abandon!
      redirect_to new_session_path(embed_params), notice: "Session abandoned."
    end

    private

    def set_session
      @flow_session = FlowEngine::FlowSession.find(params[:id])
    end

    def embed_params
      embed_mode? ? { embed: "true" } : {}
    end

    def parse_answer
      node = @flow_session.current_node
      return params[:answer] unless node

      case node.type
      when :multi_select
        params[:answer_values] || []
      when :number_matrix
        (params[:answer_fields] || {}).to_unsafe_h.transform_values(&:to_i)
      when :number
        params[:answer].to_i
      when :boolean
        params[:answer] == "true"
      else
        params[:answer]
      end
    end
  end
end
