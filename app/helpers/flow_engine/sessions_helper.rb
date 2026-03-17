# frozen_string_literal: true

module FlowEngine
  module SessionsHelper
    STEP_PARTIALS = {
      multi_select: "flow_engine/sessions/steps/multi_select",
      single_select: "flow_engine/sessions/steps/single_select",
      number_matrix: "flow_engine/sessions/steps/number_matrix",
      text: "flow_engine/sessions/steps/text",
      number: "flow_engine/sessions/steps/number",
      boolean: "flow_engine/sessions/steps/boolean",
      display: "flow_engine/sessions/steps/display"
    }.freeze

    def render_step(node, form)
      partial = STEP_PARTIALS.fetch(node.type, "flow_engine/sessions/steps/unknown")
      render partial: partial, locals: { node: node, form: form }
    end
  end
end
