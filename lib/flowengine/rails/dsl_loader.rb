# frozen_string_literal: true

module FlowEngine
  module Rails
    class DslLoader
      class << self
        def load(dsl_text, cache_key: nil)
          return FlowEngine.load_dsl(dsl_text) unless cache_key && FlowEngine::Rails.configuration.cache_definitions

          cache_fetch(cache_key) { FlowEngine.load_dsl(dsl_text) }
        end

        def clear_cache!
          mutex.synchronize { cache.clear }
        end

        private

        def cache_fetch(key)
          mutex.synchronize do
            cache[key] ||= yield
          end
        end

        def cache
          @cache ||= {}
        end

        def mutex
          @mutex ||= Mutex.new
        end
      end
    end
  end
end
