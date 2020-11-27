# == Schema Information
#
# Table name: global_scores
#
#  id               :integer          not null, primary key
#  date             :datetime         not null
#  total_required   :integer
#  general_status   :jsonb
#  country_status   :jsonb
#  fmu_status       :jsonb
#  doc_group_status :jsonb
#  fmu_type_status  :jsonb
#  country_id       :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class GlobalScore < ApplicationRecord
  belongs_to :country, optional: true
  validates_presence_of :date
  validates_uniqueness_of :date, scope: :country_id

  # Calculates the score for a given day
  # @param [Country] country The country for which to calculate the global score (if nil, will calculate all)
  def self.calculate(country = nil)
    GlobalScore.transaction do
      gs = GlobalScore.find_or_create_by(country: country, date: Date.current)
      all = country.present? ? OperatorDocument.by_country(country&.id) : OperatorDocument.all
      gs.total_required = all.count
      gs.general_status = all.group(:status).count
      gs.country_status = all.country_type.group(:status).count
      gs.fmu_status     = all.fmu_type.group(:status).count
      gs.doc_group_status = all.joins(required_operator_document: :required_operator_document_group)
                                .group('required_operator_document_groups.id').count
      gs.fmu_type_status = all.fmu_type.joins(:fmu).group('fmus.forest_type').count
      gs.save!
    end
  end
end
