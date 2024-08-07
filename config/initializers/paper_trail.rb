# frozen_string_literal: true

# config/initializers/paper_trail.rb
PaperTrail.config.enabled = true
PaperTrail.config.has_paper_trail_defaults = {
  on: %i[create update destroy]
}
PaperTrail.config.version_limit = nil
