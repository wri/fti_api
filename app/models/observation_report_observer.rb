class ObservationReportObserver < ApplicationRecord
  belongs_to :observer
  belongs_to :observation_report
end