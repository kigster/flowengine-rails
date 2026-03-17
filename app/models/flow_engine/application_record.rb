# frozen_string_literal: true

module FlowEngine
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    self.table_name_prefix = "flow_engine_"
  end
end
