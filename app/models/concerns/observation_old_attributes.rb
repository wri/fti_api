# Purpose to use with paper_trail history, to get the previous version of some attributes
module ObservationOldAttributes
  extend ActiveSupport::Concern

  EVIDENCE_TYPE_V0 = {
    "Government Documents" => 0, "Company Documents" => 1, "Photos" => 2,
    "Testimony from local communities" => 3, "Other" => 4, "Evidence presented in the report" => 5,
    "Maps" => 6
  }.freeze

  included do
    attr_accessor :evidence_type_v0
  end

  def evidence_type
    return EVIDENCE_TYPE_V0.key(evidence_type_v0) if evidence_type_v0.present?

    super
  end
end
