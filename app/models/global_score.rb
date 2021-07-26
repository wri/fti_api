# frozen_string_literal: true

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

  attr_accessor :active_filters

  # below scopes are to hack around ransack
  # maybe better instead to create custom index in active admin
  def self.ransackable_scopes(auth_object = nil)
    [:by_document_group, :by_document_type, :by_forest_type]
  end
  scope :by_document_group, ->(_param = nil) { all }
  scope :by_document_type, ->(_param = nil) { all }
  scope :by_forest_type, ->(_param = nil) { all }

  def self.headers
    @headers ||= initialize_headers
  end

  def pending
    count_by_status 'doc_pending'
  end

  def expired
    count_by_status 'doc_expired'
  end

  def invalid
    count_by_status 'doc_invalid'
  end

  def valid
    count_by_status 'doc_valid'
  end

  def not_provided
    count_by_status 'doc_not_provided'
  end

  def not_required
    count_by_status 'doc_not_required'
  end

  def count_by_status(status)
    docs = general_status.select { |d| d['s'] == OperatorDocument.statuses[status] }
    docs = docs.select { |d| d['t'] == active_filters[:by_document_type].downcase } if active_filters[:by_document_type].present?
    docs = docs.select { |d| d['g'] == active_filters[:by_document_group].to_i } if active_filters[:by_document_group].present?
    docs = docs.select { |d| d['f'] == active_filters[:by_forest_type].to_i } if active_filters[:by_forest_type].present?
    docs.count
  end

  def active_filters
    @active_filters || {}
  end

  # Calculates the score for a given day
  # @param [Country] country The country for which to calculate the global score (if nil, will calculate all)
  def self.calculate(country = nil)
    (10.days.ago.to_date..Date.today.to_date).each do |day|
      GlobalScore.transaction do
        gs = GlobalScore.find_or_create_by(country: country, date: day)
        all = country.present? ? OperatorDocument.by_country(country&.id) : OperatorDocument.all
        gs.general_status = all
          .includes(:fmu, :required_operator_document)
          .map do |d|
            {
              t: d.type === 'OperatorDocumentCountry' ? 'country' : 'fmu',
              g: d.required_operator_document.required_operator_document_group_id,
              f: Fmu.forest_types[d.fmu&.forest_type],
              s: OperatorDocument.statuses[d.status]
            }
          end
        gs.save!
      end
    end
  end

  def self.to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << headers.map{ |x| x.is_a?(Hash) ? x.values.first.map{ |y| "#{x.keys.first}-#{y[0]}" }  : x }.flatten

      find_each do |score|
        tmp_row = []
        headers.each do |h|
          if h.is_a?(Hash)
            h.values.first.each { |k| tmp_row << score[h.keys.first][k.last.to_s] }
          else
            tmp_row << score[h]
          end
        end
        csv << tmp_row
      end
    end
  end


  private

  def self.initialize_headers
    rodg_name = Arel.sql("required_operator_document_group_translations.name")
    statuses = {}
    OperatorDocument.statuses.each_key { |v| statuses[v] = v }
    [
      :date,
      :country,
      :total_required,
      { general_status: statuses },
      { country_status: statuses },
      { fmu_status: statuses },
      { doc_group_status: RequiredOperatorDocumentGroup.with_translations(I18n.locale)
                              .pluck(:id, rodg_name).map{ |x| { x[1] => x[0] } }.inject({}, :merge) },
      { fmu_type_status: Fmu.forest_types }
    ]
  end
end
