# Flowengine::Rails

[![RSpec](https://github.com/kigster/flowengine-rail/actions/workflows/rspec.yml/badge.svg)](https://github.com/kigster/flowengine-rail/actions/workflows/rspec.yml)   [![RuboCop](https://github.com/kigster/flowengine-rail/actions/workflows/rubocop.yml/badge.svg)](https://github.com/kigster/flowengine-rail/actions/workflows/rubocop.yml)   [![Default Rake Task](https://github.com/kigster/flowengine-rail/actions/workflows/main.yml/badge.svg)](https://github.com/kigster/flowengine-rail/actions/workflows/main.yml)

## Introduction

**FlowEngine::Rails** is a Rails Engine that wraps the [`flowengine`](https://github.com/kigster/flowengine) core gem with ActiveRecord persistence, a Hotwire-based wizard UI, an admin CRUD interface, and an iframe-embeddable widget. It allows non-technical users to define multi-step form flows via a Ruby DSL, store them in the database, and serve them as interactive step-by-step wizards.

Flows support seven step types: `text`, `number`, `boolean`, `single_select`, `multi_select`, `number_matrix`, and `display`. Conditional transitions between steps are driven by the core engine's rule evaluator (`if_rule:`, `contains()`, etc.).

### Key features

- **Admin UI** -- full CRUD for flow definitions with DSL validation and Mermaid diagram visualization
- **Wizard UI** -- Hotwire/Turbo-powered step-by-step form sessions with progress tracking
- **Iframe embedding** -- embed flows on external sites with auto-resizing and completion callbacks
- **Versioning** -- definitions are automatically versioned; once sessions exist, the definition becomes immutable
- **Completion callbacks** -- fire custom logic when a user finishes a flow

### Requirements

- Ruby >= 4.0.1
- Rails >= 8.1.2
- The [`flowengine`](https://github.com/kigster/flowengine) gem (`~> 0.1`)

## Usage and Integration into a Rails Application

### Installation

Add the gem to your `Gemfile`:

```ruby
gem "flowengine-rails"
```

Run the install generator, which copies migrations, creates an initializer, and mounts the engine:

```bash
bin/rails generate flow_engine:install
bin/rails db:migrate
```

This mounts the engine at `/flow_engine`. To change the mount point, edit `config/routes.rb`:

```ruby
mount FlowEngine::Rails::Engine => "/wizards"
```

### Configuration

Edit `config/initializers/flow_engine.rb`:

```ruby
FlowEngine::Rails.configure do |config|
  # Origins allowed to embed flows via iframe (use ["*"] for all)
  config.embed_allowed_origins = ["https://example.com"]

  # Cache parsed DSL definitions in memory (recommended for production)
  config.cache_definitions = Rails.env.production?

  # Callback fired when a session completes
  config.on_session_complete = ->(session) {
    LeadNotifier.qualified(session).deliver_later
  }

  # Admin authentication -- method called as a before_action
  config.admin_authentication_method = :authenticate_admin!
end
```

### Creating a flow definition

Use the generator to scaffold a flow definition file and a seed rake task:

```bash
bin/rails generate flow_engine:flow lead_qualification
```

This creates `db/flow_definitions/lead_qualification.rb` with a starter DSL template. Edit it to define your flow:

```ruby
LEAD_QUALIFICATION_DSL = <<~RUBY
  FlowEngine.define do
    start :company_size

    step :company_size do
      type :single_select
      question "How many employees does your company have?"
      options ["1-10", "11-50", "51-200", "200+"]
      transition to: :budget, if_rule: "contains(answer, '200')"
      transition to: :industry
    end

    step :industry do
      type :single_select
      question "What industry are you in?"
      options ["Technology", "Finance", "Healthcare", "Other"]
      transition to: :budget
    end

    step :budget do
      type :number
      question "What is your annual budget for this service?"
      transition to: :thank_you
    end

    step :thank_you do
      type :display
      question "Thank you! We will be in touch."
    end
  end
RUBY
```

Seed it into the database:

```bash
bin/rails flow_engine:seed:lead_qualification
```

Or create definitions programmatically:

```ruby
FlowEngine::FlowDefinition.create!(
  name: "lead_qualification",
  dsl: LEAD_QUALIFICATION_DSL
)
```

The version auto-increments per name. To make it available to users, activate it:

```ruby
FlowEngine::FlowDefinition.latest_version("lead_qualification").activate!
```

### Admin interface

The admin UI is available at `/flow_engine/admin/definitions`. To protect it, set `admin_authentication_method` in the initializer to a method defined on your `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  def authenticate_admin!
    redirect_to root_path unless current_user&.admin?
  end
end
```

From the admin UI you can create, edit, activate/deactivate definitions, and view Mermaid flow diagrams.

### Embedding flows on external sites

Add `embed.js` to the host page and call `FlowEngineEmbed.embed()`:

```html
<script src="https://yourapp.com/flow_engine/assets/flow_engine/embed.js"></script>
<div id="flow-container"></div>
<script>
  FlowEngineEmbed.embed({
    target: "#flow-container",
    definitionId: 1,
    baseUrl: "https://yourapp.com/flow_engine",
    onComplete: function(data) {
      console.log("Flow completed:", data);
    }
  });
</script>
```

The iframe auto-resizes to fit content. Make sure to add the host origin to `embed_allowed_origins` in the configuration.

### Accessing session results

After a flow session completes, its answers are available as JSON:

```ruby
session = FlowEngine::FlowSession.completed.last
session.result_json
# => { definition_name: "lead_qualification",
#      definition_version: 1,
#      answers: { "company_size" => "51-200", "budget" => 50000 },
#      history: ["company_size", "industry", "budget", "thank_you"],
#      status: "completed",
#      completed_at: "2026-03-16T..." }
```

## Troubleshooting

### DSL validation errors on save

The `FlowDefinition` model validates that the DSL string parses correctly before saving. If you see `"dsl is invalid"` errors, check that your DSL is valid Ruby and uses the correct `FlowEngine.define { ... }` syntax. Test your DSL in a console:

```ruby
FlowEngine.load_dsl(your_dsl_string)
```

### "Cannot edit definition with existing sessions"

Once a `FlowDefinition` has associated `FlowSession` records, it becomes read-only to preserve data integrity. Create a new version instead:

```ruby
old = FlowEngine::FlowDefinition.find(id)
FlowEngine::FlowDefinition.create!(name: old.name, dsl: updated_dsl)
```

### Iframe embedding returns no content

1. Verify the host origin is listed in `config.embed_allowed_origins`
1. Ensure the `?embed=true` query param is being passed (the embed script handles this automatically)
1. Check browser console for CORS errors

### Sessions stuck in `in_progress`

A session can be abandoned manually:

```ruby
FlowEngine::FlowSession.find(id).abandon!
```

To find stale sessions:

```ruby
FlowEngine::FlowSession.in_progress.where("updated_at < ?", 24.hours.ago)
```

### Migration conflicts

If your app already has tables named `flow_engine_definitions` or `flow_engine_sessions`, the install migrations will conflict. Rename or drop the existing tables before running `bin/rails db:migrate`.

## Development

### Setup

```bash
git clone https://github.com/kigster/flowengine-rails.git
cd flowengine-rails
bundle install
```

The `flowengine` core gem is expected as a sibling directory for local development:

```
flowengine-gems/
  flowengine/        # core gem
  flowengine-rails/  # this gem
```

### Running tests

Tests use an in-memory SQLite database -- no external database setup required:

```bash
bundle exec rspec       # run specs
bundle exec rubocop     # run linter
bundle exec rake        # both (default task)
```

A dummy Rails app lives in `spec/dummy/` and is used by controller and integration specs.

### Project structure

```
app/
  models/flow_engine/       # FlowDefinition, FlowSession
  controllers/flow_engine/  # SessionsController, Admin::DefinitionsController
  views/flow_engine/        # Wizard UI, admin UI, step partials
  assets/                   # embed.js, Stimulus controllers, CSS

lib/
  flowengine/rails/         # Engine, Configuration, DslLoader
  generators/flow_engine/   # install and flow generators

db/migrate/                 # Definition and session tables
spec/                       # RSpec suite with dummy app
```

### CI

Three GitHub Actions workflows run on push:

- **main.yml** -- `bundle exec rake` on Ruby 3.4.4
- **rspec.yml** -- `bundle exec rspec` on Ruby 4.0 (checks out `flowengine` core alongside)
- **rubocop.yml** -- `bundle exec rubocop` on Ruby 4.0

### Contributing

1. Fork the repo
1. Create a feature branch (`git checkout -b feature/my-feature`)
1. Commit your changes (keep commits atomic, one logical change per commit)
1. Ensure `bundle exec rake` passes
1. Open a pull request

## License

Released under the [MIT License](LICENSE.txt).
