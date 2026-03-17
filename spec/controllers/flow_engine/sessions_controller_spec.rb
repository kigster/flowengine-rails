# frozen_string_literal: true

RSpec.describe FlowEngine::SessionsController, type: :controller do
  routes { FlowEngine::Rails::Engine.routes }

  let(:definition) do
    FlowEngine::FlowDefinition.create!(name: "test_flow", dsl: SIMPLE_DSL, active: true)
  end

  let(:session_record) do
    FlowEngine::FlowSession.create!(
      flow_definition: definition,
      current_step_id: "step1",
      answers: {},
      history: ["step1"],
      status: "in_progress"
    )
  end

  describe "GET #new" do
    it "returns success" do
      definition # ensure exists
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    it "creates a session and redirects" do
      post :create, params: { definition_id: definition.id }
      expect(response).to have_http_status(:redirect)
      expect(FlowEngine::FlowSession.count).to eq(1)
    end
  end

  describe "GET #show" do
    it "renders the current step" do
      get :show, params: { id: session_record.id }
      expect(response).to have_http_status(:ok)
    end

    it "redirects to completed when session is done" do
      session_record.advance!(["B"])
      session_record.advance!("done")

      get :show, params: { id: session_record.id }
      expect(response).to redirect_to(completed_session_path(session_record))
    end
  end

  describe "PATCH #update" do
    it "advances the session and redirects" do
      patch :update, params: { id: session_record.id, answer_values: ["B"] }
      session_record.reload

      expect(response).to have_http_status(:redirect)
      expect(session_record.current_step_id).to eq("step2")
    end

    it "redirects to completed on final answer" do
      session_record.advance!(["B"])

      patch :update, params: { id: session_record.id, answer: "final" }
      expect(response).to redirect_to(completed_session_path(session_record))
    end

    it "redirects to show when session already finished" do
      session_record.update!(status: "completed")
      patch :update, params: { id: session_record.id, answer: "test" }
      expect(response).to redirect_to(session_path(session_record))
    end
  end

  describe "GET #completed" do
    it "renders completed view" do
      session_record.advance!(["B"])
      session_record.advance!("done")

      get :completed, params: { id: session_record.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #abandon" do
    it "abandons the session" do
      patch :abandon, params: { id: session_record.id }
      expect(session_record.reload.status).to eq("abandoned")
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "embed mode" do
    it "passes embed param through" do
      post :create, params: { definition_id: definition.id, embed: "true" }
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("embed=true")
    end
  end
end
