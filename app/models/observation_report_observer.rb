# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_report_observers
#
#  id                    :integer          not null, primary key
#  observation_report_id :integer
#  observer_id           :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class ObservationReportObserver < ApplicationRecord
  belongs_to :observer, touch: true
  belongs_to :observation_report, touch: true
end
