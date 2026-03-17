# frozen_string_literal: true

RSpec.describe FlowEngine::Rails::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    its(:embed_allowed_origins) { is_expected.to eq([]) }
    its(:default_layout) { is_expected.to eq("flow_engine/application") }
    its(:embed_layout) { is_expected.to eq("flow_engine/embed") }
    its(:cache_definitions) { is_expected.to be true }
    its(:on_session_complete) { is_expected.to be_nil }
    its(:admin_authentication_method) { is_expected.to be_nil }
  end

  describe "FlowEngine::Rails.configure" do
    it "yields configuration" do
      FlowEngine::Rails.configure do |c|
        c.embed_allowed_origins = ["https://example.com"]
        c.cache_definitions = false
      end

      expect(FlowEngine::Rails.configuration.embed_allowed_origins).to eq(["https://example.com"])
      expect(FlowEngine::Rails.configuration.cache_definitions).to be false
    end
  end

  describe "FlowEngine::Rails.reset_configuration!" do
    it "resets to defaults" do
      FlowEngine::Rails.configure { |c| c.cache_definitions = false }
      FlowEngine::Rails.reset_configuration!
      expect(FlowEngine::Rails.configuration.cache_definitions).to be true
    end
  end
end
