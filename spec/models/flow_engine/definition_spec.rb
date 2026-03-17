# frozen_string_literal: true

RSpec.describe FlowEngine::FlowDefinition, type: :model do
  let(:valid_dsl) { SIMPLE_DSL }

  let(:definition) do
    described_class.create!(name: "test_flow", dsl: valid_dsl)
  end

  describe "validations" do
    it "is valid with valid attributes" do
      d = described_class.new(name: "test", dsl: valid_dsl)
      expect(d).to be_valid
    end

    it "requires name" do
      d = described_class.new(dsl: valid_dsl)
      expect(d).not_to be_valid
      expect(d.errors[:name]).to include("can't be blank")
    end

    it "requires dsl" do
      d = described_class.new(name: "test")
      expect(d).not_to be_valid
      expect(d.errors[:dsl]).to include("can't be blank")
    end

    it "validates DSL parses correctly" do
      d = described_class.new(name: "test", dsl: "invalid ruby {{{{")
      expect(d).not_to be_valid
      expect(d.errors[:dsl].first).to match(/is invalid/)
    end

    it "validates uniqueness of version scoped to name" do
      definition
      d2 = described_class.new(name: "test_flow", version: definition.version, dsl: valid_dsl)
      d2.skip_auto_version = true
      expect(d2).not_to be_valid
    end
  end

  describe "auto version increment" do
    it "auto-increments version on create" do
      d1 = described_class.create!(name: "versioned", dsl: valid_dsl)
      expect(d1.version).to eq(1)

      d2 = described_class.create!(name: "versioned", dsl: valid_dsl)
      expect(d2.version).to eq(2)
    end

    it "does not override explicit version when skip_auto_version is set" do
      d = described_class.new(name: "explicit", version: 5, dsl: valid_dsl)
      d.skip_auto_version = true
      d.save!
      expect(d.version).to eq(5)
    end
  end

  describe "#parsed_definition" do
    it "returns a FlowEngine::Definition" do
      expect(definition.parsed_definition).to be_a(FlowEngine::Definition)
    end

    it "caches the result" do
      expect(definition.parsed_definition).to equal(definition.parsed_definition)
    end
  end

  describe "#activate! / #deactivate!" do
    it "activates and deactivates" do
      definition.activate!
      expect(definition.reload.active?).to be true

      definition.deactivate!
      expect(definition.reload.active?).to be false
    end

    it "deactivates other versions when activating" do
      d1 = described_class.create!(name: "switch", dsl: valid_dsl)
      d1.activate!

      d2 = described_class.create!(name: "switch", dsl: valid_dsl)
      d2.activate!

      expect(d1.reload.active?).to be false
      expect(d2.reload.active?).to be true
    end
  end

  describe "#readonly?" do
    it "returns false when no sessions exist" do
      expect(definition.readonly?).to be false
    end

    it "returns true when sessions exist" do
      FlowEngine::FlowSession.create!(
        flow_definition: definition,
        current_step_id: "step1",
        status: "in_progress"
      )
      expect(definition.readonly?).to be true
    end
  end

  describe "#mermaid_diagram" do
    it "returns mermaid syntax" do
      diagram = definition.mermaid_diagram
      expect(diagram).to include("flowchart TD")
      expect(diagram).to include("step1")
    end
  end

  describe "#total_steps" do
    it "returns the number of steps" do
      expect(definition.total_steps).to eq(2)
    end
  end

  describe "scopes" do
    it ".active returns only active definitions" do
      definition.activate!
      inactive = described_class.create!(name: "inactive_flow", dsl: valid_dsl)

      expect(described_class.active).to include(definition)
      expect(described_class.active).not_to include(inactive)
    end

    it ".by_name filters by name" do
      definition
      other = described_class.create!(name: "other_flow", dsl: valid_dsl)

      expect(described_class.by_name("test_flow")).to include(definition)
      expect(described_class.by_name("test_flow")).not_to include(other)
    end
  end
end
