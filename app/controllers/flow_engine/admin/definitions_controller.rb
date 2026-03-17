# frozen_string_literal: true

module FlowEngine
  module Admin
    class DefinitionsController < ApplicationController
      before_action :authenticate_admin!
      before_action :set_definition, only: %i[show edit update destroy activate deactivate mermaid]

      def index
        @definitions = FlowEngine::FlowDefinition.order(:name, version: :desc)
        @grouped = @definitions.group_by(&:name)
      end

      def show; end

      def new
        @definition = FlowEngine::FlowDefinition.new
      end

      def create
        @definition = FlowEngine::FlowDefinition.new(definition_params)

        if @definition.save
          redirect_to admin_definition_path(@definition), notice: "Definition created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        return unless @definition.readonly?

        redirect_to admin_definition_path(@definition),
                    alert: "Cannot edit definition with existing sessions. Create a new version instead."
        nil
      end

      def update
        if @definition.readonly?
          redirect_to admin_definition_path(@definition),
                      alert: "Cannot edit definition with existing sessions."
          return
        end

        if @definition.update(definition_params)
          FlowEngine::Rails::DslLoader.clear_cache!
          redirect_to admin_definition_path(@definition), notice: "Definition updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @definition.flow_sessions.exists?
          redirect_to admin_definitions_path, alert: "Cannot delete definition with existing sessions."
          return
        end

        @definition.destroy!
        redirect_to admin_definitions_path, notice: "Definition deleted."
      end

      def activate
        @definition.activate!
        redirect_to admin_definition_path(@definition), notice: "Definition activated."
      end

      def deactivate
        @definition.deactivate!
        redirect_to admin_definition_path(@definition), notice: "Definition deactivated."
      end

      def mermaid
        @diagram = @definition.mermaid_diagram
      end

      private

      def set_definition
        @definition = FlowEngine::FlowDefinition.find(params[:id])
      end

      def definition_params
        params.expect(definition: %i[name dsl])
      end

      def authenticate_admin!
        method_name = FlowEngine::Rails.configuration.admin_authentication_method
        return unless method_name

        send(method_name)
      end
    end
  end
end
