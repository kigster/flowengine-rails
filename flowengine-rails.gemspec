# frozen_string_literal: true

require_relative "lib/flowengine/rails/version"

Gem::Specification.new do |spec|
  spec.name = "flowengine-rails"
  spec.version = FlowEngine::Rails::VERSION
  spec.authors = ["Konstantin Gredeskoul"]
  spec.email = ["kigster@gmail.com"]

  spec.summary = "Rails Engine adapter for FlowEngine — persistence, web wizard UI, and admin CRUD"
  spec.description = "FlowEngine::Rails provides ActiveRecord persistence, Hotwire-based web wizard UI, " \
                     "admin CRUD for flow definitions, and an iframe-embeddable widget. " \
                     "Built on the flowengine core gem."
  spec.homepage = "https://github.com/kigster/flowengine-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.1"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kigster/flowengine-rails"
  spec.metadata["changelog_uri"] = "https://github.com/kigster/flowengine-rails/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "flowengine", "~> 0.1"
  spec.add_dependency "rails", ">= 8.0.1"
  spec.add_dependency "stimulus-rails", "~> 1.0"
  spec.add_dependency "turbo-rails", "~> 2.0"
end
