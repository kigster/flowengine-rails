# frozen_string_literal: true

RSpec.describe FlowEngine::Rails::DslLoader do
  let(:valid_dsl) { SIMPLE_DSL }

  describe ".load" do
    it "parses valid DSL and returns a Definition" do
      result = described_class.load(valid_dsl)
      expect(result).to be_a(FlowEngine::Definition)
    end

    it "raises on invalid DSL" do
      expect do
        described_class.load("invalid ruby {{{{")
      end.to raise_error(FlowEngine::Errors::DefinitionError)
    end

    context "with caching enabled" do
      before do
        FlowEngine::Rails.configure { |c| c.cache_definitions = true }
      end

      it "caches by cache_key" do
        result1 = described_class.load(valid_dsl, cache_key: "test:1")
        result2 = described_class.load(valid_dsl, cache_key: "test:1")
        expect(result1).to equal(result2)
      end

      it "does not cache when no cache_key given" do
        result1 = described_class.load(valid_dsl)
        result2 = described_class.load(valid_dsl)
        expect(result1).not_to equal(result2)
      end
    end

    context "with caching disabled" do
      before do
        FlowEngine::Rails.configure { |c| c.cache_definitions = false }
      end

      it "does not cache even with cache_key" do
        result1 = described_class.load(valid_dsl, cache_key: "test:2")
        result2 = described_class.load(valid_dsl, cache_key: "test:2")
        expect(result1).not_to equal(result2)
      end
    end
  end

  describe ".clear_cache!" do
    it "clears the cache" do
      FlowEngine::Rails.configure { |c| c.cache_definitions = true }

      result1 = described_class.load(valid_dsl, cache_key: "test:3")
      described_class.clear_cache!
      result2 = described_class.load(valid_dsl, cache_key: "test:3")

      expect(result1).not_to equal(result2)
    end
  end
end
