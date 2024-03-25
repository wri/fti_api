# frozen_string_literal: true

# config/initializers/paper_trail.rb
PaperTrail.config.enabled = true
PaperTrail.config.has_paper_trail_defaults = {
  on: %i[create update destroy]
}
PaperTrail.config.version_limit = nil

# TODO: switch to jsonb columns instead of text columns and yaml serialization
::ActiveRecord.yaml_column_permitted_classes = [
  ::ActiveRecord::Type::Time::Value,
  ::ActiveSupport::TimeWithZone,
  ::ActiveSupport::TimeZone,
  ::BigDecimal,
  ::Date,
  ::Symbol,
  ::Time
]
