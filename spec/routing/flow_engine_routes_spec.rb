# frozen_string_literal: true

RSpec.describe "FlowEngine routes", type: :routing do
  routes { FlowEngine::Rails::Engine.routes }

  describe "sessions" do
    it "routes GET /sessions/new" do
      expect(get: "/sessions/new").to route_to("flow_engine/sessions#new")
    end

    it "routes POST /sessions" do
      expect(post: "/sessions").to route_to("flow_engine/sessions#create")
    end

    it "routes GET /sessions/:id" do
      expect(get: "/sessions/1").to route_to("flow_engine/sessions#show", id: "1")
    end

    it "routes PATCH /sessions/:id" do
      expect(patch: "/sessions/1").to route_to("flow_engine/sessions#update", id: "1")
    end

    it "routes GET /sessions/:id/completed" do
      expect(get: "/sessions/1/completed").to route_to("flow_engine/sessions#completed", id: "1")
    end

    it "routes PATCH /sessions/:id/abandon" do
      expect(patch: "/sessions/1/abandon").to route_to("flow_engine/sessions#abandon", id: "1")
    end
  end

  describe "admin definitions" do
    it "routes GET /admin/definitions" do
      expect(get: "/admin/definitions").to route_to("flow_engine/admin/definitions#index")
    end

    it "routes POST /admin/definitions" do
      expect(post: "/admin/definitions").to route_to("flow_engine/admin/definitions#create")
    end

    it "routes GET /admin/definitions/:id" do
      expect(get: "/admin/definitions/1").to route_to("flow_engine/admin/definitions#show", id: "1")
    end

    it "routes PATCH /admin/definitions/:id" do
      expect(patch: "/admin/definitions/1").to route_to("flow_engine/admin/definitions#update", id: "1")
    end

    it "routes DELETE /admin/definitions/:id" do
      expect(delete: "/admin/definitions/1").to route_to("flow_engine/admin/definitions#destroy", id: "1")
    end

    it "routes POST /admin/definitions/:id/activate" do
      expect(post: "/admin/definitions/1/activate").to route_to("flow_engine/admin/definitions#activate", id: "1")
    end

    it "routes POST /admin/definitions/:id/deactivate" do
      expect(post: "/admin/definitions/1/deactivate").to route_to("flow_engine/admin/definitions#deactivate", id: "1")
    end

    it "routes GET /admin/definitions/:id/mermaid" do
      expect(get: "/admin/definitions/1/mermaid").to route_to("flow_engine/admin/definitions#mermaid", id: "1")
    end
  end

  describe "root" do
    it "routes to sessions#new" do
      expect(get: "/").to route_to("flow_engine/sessions#new")
    end
  end
end
