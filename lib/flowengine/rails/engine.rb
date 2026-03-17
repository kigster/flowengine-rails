# frozen_string_literal: true

module FlowEngine
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace FlowEngine

      initializer "flow_engine.assets" do |app|
        app.config.assets.paths << root.join("app", "assets", "stylesheets") if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app", "assets", "javascripts") if app.config.respond_to?(:assets)
      end

      initializer "flow_engine.importmap", before: "importmap" do |app|
        if app.config.respond_to?(:importmap) && root.join("config",
                                                           "importmap.rb").exist?
          app.config.importmap.paths << root.join("config", "importmap.rb")
        end
      end

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot, dir: "spec/factories"
      end
    end
  end
end
