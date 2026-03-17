# frozen_string_literal: true

RSpec.describe FlowEngine::FlowSession, type: :model do
  let(:definition) do
    FlowEngine::FlowDefinition.create!(name: "test_flow", dsl: SIMPLE_DSL)
  end

  let(:session) do
    described_class.create!(
      flow_definition: definition,
      current_step_id: "step1",
      answers: {},
      history: ["step1"],
      status: "in_progress"
    )
  end

  describe "validations" do
    it "requires valid status" do
      s = described_class.new(flow_definition: definition, status: "invalid")
      expect(s).not_to be_valid
    end

    it "allows valid statuses" do
      %w[in_progress completed abandoned].each do |status|
        s = described_class.new(flow_definition: definition, status: status, current_step_id: "step1")
        expect(s).to be_valid
      end
    end
  end

  describe "#engine" do
    it "returns a FlowEngine::Engine from current state" do
      eng = session.engine
      expect(eng).to be_a(FlowEngine::Engine)
      expect(eng.current_step_id).to eq(:step1)
    end
  end

  describe "#advance!" do
    it "advances the session and persists state" do
      session.advance!(["B"])
      session.reload

      expect(session.current_step_id).to eq("step2")
      expect(session.answers).to eq({ "step1" => ["B"] })
      expect(session.history).to eq(%w[step1 step2])
      expect(session.status).to eq("in_progress")
    end

    it "completes when flow finishes" do
      session.advance!(["B"])
      session.reload
      session.advance!("final answer")
      session.reload

      expect(session.status).to eq("completed")
      expect(session.current_step_id).to be_nil
    end

    it "fires completion callback" do
      callback_called = false
      FlowEngine::Rails.configure do |config|
        config.on_session_complete = ->(_s) { callback_called = true }
      end

      session.advance!(["B"])
      session.advance!("done")

      expect(callback_called).to be true
    end
  end

  describe "#abandon!" do
    it "sets status to abandoned" do
      session.abandon!
      expect(session.reload.status).to eq("abandoned")
    end
  end

  describe "#in_progress? / #completed? / #finished?" do
    it "reports correct status" do
      expect(session.in_progress?).to be true
      expect(session.completed?).to be false
      expect(session.finished?).to be false

      session.advance!(["B"])
      session.advance!("done")
      session.reload

      expect(session.in_progress?).to be false
      expect(session.completed?).to be true
      expect(session.finished?).to be true
    end

    it "reports abandoned as finished" do
      session.abandon!
      expect(session.finished?).to be true
    end
  end

  describe "#current_node" do
    it "returns the current node" do
      node = session.current_node
      expect(node).to be_a(FlowEngine::Node)
      expect(node.id).to eq(:step1)
    end

    it "returns nil when step_id is blank" do
      session.update!(current_step_id: nil, status: "completed")
      expect(session.current_node).to be_nil
    end
  end

  describe "#progress_percentage" do
    it "returns 0 at start" do
      s = described_class.create!(
        flow_definition: definition,
        current_step_id: "step1",
        history: [],
        status: "in_progress"
      )
      expect(s.progress_percentage).to eq(0)
    end

    it "returns percentage based on history" do
      expect(session.progress_percentage).to eq(50) # 1 of 2 steps
    end

    it "caps at 100" do
      session.update!(history: %w[step1 step2 step1])
      expect(session.progress_percentage).to eq(100)
    end
  end

  describe "#result_json" do
    it "returns result hash" do
      result = session.result_json
      expect(result[:definition_name]).to eq("test_flow")
      expect(result[:answers]).to eq({})
      expect(result[:status]).to eq("in_progress")
    end
  end

  describe "scopes" do
    it ".in_progress returns in_progress sessions" do
      expect(described_class.in_progress).to include(session)
    end

    it ".completed returns completed sessions" do
      session.advance!(["B"])
      session.advance!("done")

      expect(described_class.completed).to include(session)
    end
  end

  describe "round-trip persistence" do
    it "survives JSON serialization through advance cycles" do
      session.advance!(["B"])
      session.reload

      eng = session.engine
      expect(eng.current_step_id).to eq(:step2)
      expect(eng.answers).to eq({ step1: ["B"] })
    end
  end
end
