# FlowEngine Rails

## What This Gem Does

`flowengine-rails` is a Rails Engine (v0.1.0) that wraps the `flowengine` core gem with ActiveRecord persistence, a Hotwire-based web wizard UI, an admin CRUD interface, and an iframe-embeddable widget. It lets non-technical users define multi-step form flows via a Ruby DSL, store them in the database, and serve them to end users as interactive step-by-step wizards.

The target application is **Qualified.at** -- a lead qualification service where flows are embedded in external client sites via iframes.

## Dependency on `flowengine` Core Gem

The core gem (`flowengine`, published on RubyGems as v0.4.0, source at `github.com/kigster/flowengine`) provides:

- **DSL** for defining flows: `FlowEngine.define { ... }` with steps, transitions, rules
- **Engine** (state machine): `FlowEngine::Engine` drives step traversal, answers, history
- **Node** objects representing individual steps with types (`:text`, `:boolean`, `:number`, `:single_select`, `:multi_select`, `:number_matrix`, `:display`)
- **Graph/MermaidExporter** for diagram visualization
- **Rules/Evaluator** for conditional transitions (`if_rule:`, `contains()`, etc.)
- **Validation** for DSL correctness

This gem calls into `flowengine` via:
- `FlowEngine.load_dsl(dsl_text)` -- parses DSL string into a Definition
- `FlowEngine::Engine.new(definition)` / `FlowEngine::Engine.from_state(definition, state)` -- creates/restores engine
- `engine.answer(value)`, `engine.to_state`, `engine.finished?` -- drives flow
- `definition.step_ids`, `definition.step(id)` -- introspects steps
- `FlowEngine::Graph::MermaidExporter` -- generates Mermaid diagrams

**Local development**: `Gemfile` uses `path: "../flowengine"` (sibling directory). **CI/branches**: changed to `github: "kigster/flowengine"`. The gemspec declares `spec.add_dependency "flowengine", "~> 0.1"`.

## Repository Layout

```
flowengine-rails.gemspec        # Gem metadata, deps: flowengine ~> 0.1, rails >= 8.0.1, stimulus-rails, turbo-rails
Gemfile                         # Dev deps: rspec-rails, rspec-its, rubocop, capybara, simplecov, sqlite3
Rakefile                        # Default task: spec + rubocop

lib/
  flowengine/rails.rb           # Entry point, Configuration singleton, Error class
  flowengine/rails/version.rb   # VERSION = "0.1.0"
  flowengine/rails/configuration.rb  # embed_allowed_origins, layouts, cache, callbacks, admin auth
  flowengine/rails/dsl_loader.rb     # Thread-safe in-memory cache around FlowEngine.load_dsl
  flowengine/rails/engine.rb         # Rails::Engine with asset paths, importmap, generator config
  generators/
    flow_engine/install/        # rails g flow_engine:install -- migrations, initializer, route mount
    flow_engine/flow/           # rails g flow_engine:flow NAME -- definition file + seed rake task

app/
  models/flow_engine/
    application_record.rb       # Base AR class
    flow_definition.rb          # name, version, dsl (text), active (boolean). Validates DSL parses.
                                # Auto-increments version on create. activate!/deactivate! toggles.
                                # readonly? when sessions exist. Generates mermaid diagrams.
    flow_session.rb             # belongs_to definition. Tracks current_step_id, answers (JSON),
                                # history (JSON), status (in_progress/completed/abandoned).
                                # advance!(answer) drives the engine. fire_completion_callback on complete.
  controllers/flow_engine/
    application_controller.rb   # Embed mode detection (?embed=true), CORS headers, layout switching
    sessions_controller.rb      # new, create, show, update, completed, abandon
                                # Parses answer by step type (multi_select->array, number->int, etc.)
    admin/definitions_controller.rb  # Full CRUD + activate/deactivate/mermaid. Admin auth via config.
  helpers/flow_engine/
    sessions_helper.rb          # render_step(node, form) dispatches to type-specific partials
  views/
    flow_engine/sessions/       # new, show, completed templates
    flow_engine/sessions/steps/ # Partials: _boolean, _text, _number, _single_select,
                                #   _multi_select, _number_matrix, _display, _unknown
    flow_engine/admin/definitions/  # index, show, new, edit, _form, mermaid
    layouts/flow_engine/        # application.html.erb (standalone), embed.html.erb (iframe)
  assets/
    javascripts/flow_engine/    # embed.js (iframe resizer), progress_controller.js, step_controller.js
    stylesheets/flow_engine/    # application.css (full standalone stylesheet)

config/routes.rb                # sessions (new/create/show/update + completed/abandon)
                                # admin/definitions (CRUD + activate/deactivate/mermaid)
                                # root -> sessions#new

db/migrate/
  01_create_flow_engine_definitions.rb  # name, version, dsl, active. Unique index on [name, version].
  02_create_flow_engine_sessions.rb     # definition_id (FK), current_step_id, answers/history/metadata (JSON), status

spec/
  spec_helper.rb                # SQLite in-memory, schema created inline, SIMPLE_DSL fixture
  dummy/                        # Minimal Rails 8 app (SQLite :memory:, engine mounted at /flow_engine)
  controllers/                  # Request specs for sessions + admin/definitions
  models/                       # Unit specs for FlowDefinition, FlowSession
  lib/                          # Specs for Configuration, DslLoader
  routing/                      # Route specs

.github/workflows/
  main.yml                      # Ruby 3.4.4, bundle exec rake (spec + rubocop)
  rspec.yml                     # Ruby 4.0, checks out kigster/flowengine alongside, bundle exec rspec
  rubocop.yml                   # Ruby 4.0, bundle exec rubocop
```

## Database Schema

**flow_engine_definitions**: `name` (string), `version` (integer, auto-incremented per name), `dsl` (text, Ruby DSL source), `active` (boolean). Unique index on `[name, version]`.

**flow_engine_sessions**: `definition_id` (FK), `current_step_id` (string), `answers` (JSON), `history` (JSON, array of visited step IDs), `status` (string: in_progress/completed/abandoned), `metadata` (JSON).

## Configuration

```ruby
FlowEngine::Rails.configure do |config|
  config.embed_allowed_origins = ["https://example.com"]  # CORS for iframe embed
  config.default_layout = "flow_engine/application"        # Standalone layout
  config.embed_layout = "flow_engine/embed"                # Iframe layout
  config.cache_definitions = true                          # In-memory DSL parse cache
  config.on_session_complete = ->(session) { ... }         # Completion callback
  config.admin_authentication_method = :authenticate_admin! # Admin before_action
end
```

## Step Types and Answer Parsing

| Step type       | View partial       | Answer param          | Parsed as            |
|-----------------|--------------------|-----------------------|----------------------|
| `:text`         | `_text`            | `params[:answer]`     | String               |
| `:number`       | `_number`          | `params[:answer]`     | Integer (`.to_i`)    |
| `:boolean`      | `_boolean`         | `params[:answer]`     | Boolean (`== "true"`)|
| `:single_select`| `_single_select`   | `params[:answer]`     | String               |
| `:multi_select` | `_multi_select`    | `params[:answer_values]` | Array             |
| `:number_matrix`| `_number_matrix`   | `params[:answer_fields]` | Hash (string->int)|
| `:display`      | `_display`         | (none, info-only)     | N/A                  |

## Running Tests and Linting

```bash
bundle exec rspec          # Tests (SQLite in-memory, no external DB needed)
bundle exec rubocop        # Lint
bundle exec rake           # Both (default task)
```

## CI Notes

- **Gemfile.lock must include `x86_64-linux` platform** (`bundle lock --add-platform x86_64-linux`)
- The `rspec.yml` workflow checks out `kigster/flowengine` as a sibling directory for the path dependency
- The `main.yml` workflow runs on Ruby 3.4.4; `rspec.yml` and `rubocop.yml` run on Ruby 4.0
- Required Ruby version: `>= 4.0.1` (gemspec)

## RuboCop Configuration

- Target Ruby 4.0, double quotes enforced, frozen string literal required
- Line length max 120, method length max 20
- `spec/dummy/` excluded from cops
- `inherit_from: .rubocop_todo.yml`

## Key Architectural Patterns

- **Isolated namespace**: all code under `FlowEngine` module, engine uses `isolate_namespace FlowEngine`
- **Immutable definitions**: once a `FlowDefinition` has sessions, it becomes `readonly?`; users must create a new version
- **State reconstruction**: `FlowSession#engine` rebuilds `FlowEngine::Engine` from persisted state on every request (stateless controller pattern)
- **Embed mode**: `?embed=true` query param switches layout and enables CORS headers
- **Thread-safe caching**: `DslLoader` uses `Mutex` for DSL parse cache
