# frozen_string_literal: true

RSpec.describe FlowEngine::Admin::DefinitionsController, type: :controller do
  routes { FlowEngine::Rails::Engine.routes }

  let(:valid_dsl) { SIMPLE_DSL }

  let(:definition) do
    FlowEngine::FlowDefinition.create!(name: "test_flow", dsl: valid_dsl)
  end

  describe "GET #index" do
    it "returns success" do
      definition
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #show" do
    it "returns success" do
      get :show, params: { id: definition.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #new" do
    it "returns success" do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    it "creates a definition" do
      expect do
        post :create, params: { definition: { name: "new_flow", dsl: valid_dsl } }
      end.to change(FlowEngine::FlowDefinition, :count).by(1)

      expect(response).to have_http_status(:redirect)
    end

    it "re-renders on invalid input" do
      post :create, params: { definition: { name: "", dsl: valid_dsl } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET #edit" do
    it "returns success when editable" do
      get :edit, params: { id: definition.id }
      expect(response).to have_http_status(:ok)
    end

    it "redirects when readonly" do
      FlowEngine::FlowSession.create!(
        flow_definition: definition,
        current_step_id: "step1",
        status: "in_progress"
      )

      get :edit, params: { id: definition.id }
      expect(response).to redirect_to(admin_definition_path(definition))
    end
  end

  describe "PATCH #update" do
    it "updates the definition" do
      new_dsl = <<~RUBY
        FlowEngine.define do
          start :q1
          step :q1 do
            type :text
            question "Updated?"
          end
        end
      RUBY

      patch :update, params: { id: definition.id, definition: { dsl: new_dsl } }
      expect(response).to have_http_status(:redirect)
      expect(definition.reload.dsl).to eq(new_dsl)
    end

    it "rejects update when readonly" do
      FlowEngine::FlowSession.create!(
        flow_definition: definition,
        current_step_id: "step1",
        status: "in_progress"
      )

      patch :update, params: { id: definition.id, definition: { dsl: valid_dsl } }
      expect(response).to redirect_to(admin_definition_path(definition))
    end
  end

  describe "DELETE #destroy" do
    it "deletes the definition" do
      definition
      expect do
        delete :destroy, params: { id: definition.id }
      end.to change(FlowEngine::FlowDefinition, :count).by(-1)
    end

    it "refuses to delete with sessions" do
      FlowEngine::FlowSession.create!(
        flow_definition: definition,
        current_step_id: "step1",
        status: "in_progress"
      )

      expect do
        delete :destroy, params: { id: definition.id }
      end.not_to change(FlowEngine::FlowDefinition, :count)
    end
  end

  describe "POST #activate" do
    it "activates the definition" do
      post :activate, params: { id: definition.id }
      expect(definition.reload.active?).to be true
    end
  end

  describe "POST #deactivate" do
    it "deactivates the definition" do
      definition.activate!
      post :deactivate, params: { id: definition.id }
      expect(definition.reload.active?).to be false
    end
  end

  describe "GET #mermaid" do
    it "returns the mermaid diagram" do
      get :mermaid, params: { id: definition.id }
      expect(response).to have_http_status(:ok)
    end
  end
end
