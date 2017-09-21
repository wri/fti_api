# frozen_string_literal: true
# == Schema Information
#
# Table name: operators
#
#  id                                 :integer          not null, primary key
#  operator_type                      :string
#  country_id                         :integer
#  concession                         :string
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  is_active                          :boolean          default(TRUE)
#  logo                               :string
#  operator_id                        :string
#  percentage_valid_documents_all     :float
#  percentage_valid_documents_country :float
#  percentage_valid_documents_fmu     :float
#  certification                      :integer
#  score_absolute                     :float
#  score                              :integer
#  obs_per_visit                      :float
#  fa_id                              :string
#  address                            :string
#  website                            :string
#

class Operator < ApplicationRecord
  translates :name, :details
  active_admin_translates :name, :details

  mount_base64_uploader :logo, LogoUploader

  enum certification: { fsc: 0, pefc: 1, olb: 2 }

  TYPES = ['Logging company', 'Artisanal', 'Community forest', 'Estate', 'Industrial agriculture', 'Mining company',
           'Sawmill', 'Other', 'Unknown'].freeze

  belongs_to :country, inverse_of: :operators, optional: true

  has_many :observations, -> { active },  inverse_of: :operator
  has_many :users, inverse_of: :operator
  has_many :fmus, inverse_of: :operator

  has_many :operator_documents, -> { valid }
  has_many :operator_document_countries, -> { valid }
  has_many :operator_document_fmus, -> { valid }

  after_create :create_operator_id
  after_create :create_documents

  validates :name, presence: true
  validates :website, url: true, if: lambda {|x| x.website.present?}
  validates :operator_type, inclusion: { in: TYPES }

  scope :by_name_asc, -> {
    includes(:translations).with_translations(I18n.available_locales)
                           .order('operator_translations.name ASC')
  }

  default_scope { includes(:translations) }

  scope :filter_by_country_ids,   ->(country_ids)     { where(country_id: country_ids.split(',')) }

  class << self
    def fetch_all(options)
      country_ids = options['country_ids']    if options.present? && options['country_ids'].present?

      operators = includes(:country, :users)
      operators = operators.filter_by_country_ids(country_ids)    if country_ids.present?
      operators
    end

    def operator_select
      by_name_asc.map { |c| [c.name, c.id] }
    end

    def types
      TYPES
    end

    def translated_types
      types.map { |t| [I18n.t("operator_types.#{t}", default: t), t.camelize] }
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end

  def update_valid_documents_percentages
    self.percentage_valid_documents_all = operator_documents.where(status: OperatorDocument.statuses[:doc_valid]).count.to_f / operator_documents.count.to_f rescue 0
    self.percentage_valid_documents_fmu = operator_documents.where(type: 'OperatorDocumentFmu', status: OperatorDocument.statuses[:doc_valid]).count.to_f / operator_documents.where(type: 'OperatorDocumentFmu').count.to_f rescue 0
    self.percentage_valid_documents_country = operator_documents.where(type: 'OperatorDocumentCountry', status: OperatorDocument.statuses[:doc_valid]).count.to_f / operator_documents.where(type: 'OperatorDocumentCountry').count.to_f rescue 0

    self.percentage_valid_documents_all = 0 if self.percentage_valid_documents_all.nan?
    self.percentage_valid_documents_country = 0 if self.percentage_valid_documents_country.nan?
    self.percentage_valid_documents_fmu = 0 if self.percentage_valid_documents_fmu.nan?

    self.save!
  end


  def calculate_observations_scores
    number_of_visits = observations.select('date(publication_date)').group('date(publication_date)').count
    number_of_visits = number_of_visits.keys.count

    # When there are no observations
    if number_of_visits == 0
      self.obs_per_visit = nil
      self.score_absolute = nil
      save!
      return
    end

    self.obs_per_visit = observations.count.to_f / number_of_visits rescue nil

    high = observations.joins(:severity).where('severities.level = 3').count.to_f / number_of_visits
    medium = observations.joins(:severity).where('severities.level = 2').count.to_f / number_of_visits
    low = observations.joins(:severity).where('severities.level = 1').count.to_f / number_of_visits
    unknown = observations.joins(:severity).where('severities.level = 0').count.to_f / number_of_visits
    self.score_absolute  = (4 * high + 2 * medium + 2 * unknown + low).to_f / 9

    save!
  end

  class << self
    def calculate_scores
      Operator.where(score_absolute: nil).update_all(score: 0)

      number_operators = Operator.where.not(score_absolute: nil).count
      third_operators = (number_operators / 3).to_i
      Operator.where.not(score_absolute: nil).order(:score_absolute)
          .limit(third_operators).update_all(score: 1)
      Operator.where.not(score_absolute: nil)
          .order("score_absolute LIMIT #{third_operators} OFFSET #{third_operators}").update_all(score: 2)
      Operator.where.not(score_absolute: nil).order("score_absolute OFFSET #{2 * third_operators}").update_all(score: 3)
    end
  end


  private

  def create_operator_id
    if country_id.present?
      update_columns(operator_id: "#{country.iso}-unknown-#{id}")
    else
      update_columns(operator_id: "na-unknown-#{id}")
    end
  end

  def create_documents
    country = RequiredOperatorDocument.where(country_id: country_id).any? ? country_id : nil

    RequiredOperatorDocumentCountry.where(country_id: country).find_each do |rodc|
      OperatorDocumentCountry.where(required_operator_document_id: rodc.id, operator_id: id).first_or_create do |odc|
        odc.update_attributes!(status: OperatorDocument.statuses[:doc_not_provided], current: true)
      end
    end

    RequiredOperatorDocumentFmu.where(country_id: country).find_each do |rodf|
      Fmu.where(operator_id: id).find_each do |fmu|
        OperatorDocumentFmu.where(required_operator_document_id: rodf.id, operator_id: id, fmu_id: fmu.id).first_or_create do |odf|
          odf.update_attributes!(status: OperatorDocument.statuses[:doc_not_provided], current: true)
        end
      end
    end
  end
end
