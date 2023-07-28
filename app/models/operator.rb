# frozen_string_literal: true

# == Schema Information
#
# Table name: operators
#
#  id                :integer          not null, primary key
#  operator_type     :string
#  country_id        :integer
#  concession        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default(TRUE), not null
#  logo              :string
#  operator_id       :string
#  fa_id             :string
#  address           :string
#  website           :string
#  approved          :boolean          default(TRUE), not null
#  email             :string
#  holding_id        :integer
#  country_doc_rank  :integer
#  country_operators :integer
#  name              :string
#  details           :string
#

class Operator < ApplicationRecord
  has_paper_trail

  validates :name, presence: true, uniqueness: {case_sensitive: false}

  mount_base64_uploader :logo, LogoUploader
  attr_accessor :delete_logo

  TYPES = ["Logging company", "Artisanal", "Community forest", "Estate", "Industrial agriculture", "Mining company",
    "Sawmill", "Other", "Unknown"].freeze

  belongs_to :country, inverse_of: :operators, optional: true
  belongs_to :holding, inverse_of: :operators, optional: true
  has_many :all_operator_documents, class_name: "OperatorDocument"

  has_many :observations, -> { active.distinct }, inverse_of: :operator, dependent: :nullify
  has_many :all_observations, class_name: "Observation", inverse_of: :operator, dependent: :nullify
  has_many :users, inverse_of: :operator, dependent: :destroy

  has_many :fmu_operators, -> { where(current: true) }, inverse_of: :operator, dependent: :destroy
  has_many :fmus, through: :fmu_operators
  has_many :all_fmu_operators, class_name: "FmuOperator", inverse_of: :operator, dependent: :destroy
  has_many :all_fmus, through: :all_fmu_operators, source: :fmu

  has_many :operator_documents
  has_many :operator_document_countries
  has_many :operator_document_fmus

  has_many :operator_document_histories
  has_many :operator_document_country_histories
  has_many :operator_document_fmu_histories

  has_many :score_operator_documents
  has_one :score_operator_document, -> { current }, class_name: "ScoreOperatorDocument", inverse_of: :operator
  has_many :score_operator_observations
  has_one :score_operator_observation, -> { current }, class_name: "ScoreOperatorObservation", inverse_of: :operator

  has_many :sawmills

  accepts_nested_attributes_for :fmu_operators, :all_fmu_operators

  before_validation { remove_logo! if delete_logo == "1" }

  before_save :set_slug, if: :name_changed?

  after_create :create_operator_id
  after_create :create_documents

  after_update :recalculate_scores, if: :saved_change_to_approved?
  after_update :clean_document_cache, if: :saved_change_to_approved?
  after_update :create_documents, if: -> { saved_change_to_fa_id? && fa_id_before_last_save.blank? }
  after_update :refresh_ranking, if: -> { saved_change_to_fa_id? || saved_change_to_is_active? }

  after_save :update_operator_name_on_fmus, if: :saved_change_to_name?

  validates :name, presence: true
  validates :name, uniqueness: {case_sensitive: false}
  validates :website, url: true, if: lambda { |x| x.website.present? }
  validates :operator_type, inclusion: {in: TYPES, message: "can't be %{value}. Valid values are: #{TYPES.join(", ")} "}
  validates :country, presence: true, on: :create

  scope :by_name_asc, -> { order(name: :asc) }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :fa_operator, -> { where("fa_id <> ''") }
  scope :approved, -> { where(approved: true) }
  scope :newsletter_eligible, -> { active.approved.fa_operator }

  scope :filter_by_country_ids, ->(country_ids) { where(country_id: country_ids.split(",")) }

  # Returns the operators that should have documents for a particular country
  # When that country is null, it returns the list of operators that should have generic documents
  scope :for_document_country, ->(country_id) {
    if country_id.nil?
      fa_operator.where.not(country_id: Country.active.uniq.pluck(:id))
    else
      fa_operator.where(country_id: country_id)
    end
  }

  class << self
    def fetch_all(options)
      country_ids = options["country_ids"] if options.present? && options["country_ids"].present?

      operators = includes(:country, :users)
      operators = operators.filter_by_country_ids(country_ids) if country_ids.present?
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

  def can_hard_delete?
    all_fmus.with_deleted.none? &&
      all_observations.with_deleted.none? &&
      users.none? &&
      operator_documents.with_deleted.none?
  end

  def set_slug
    self.slug = name.parameterize
  end

  private

  # Saves the fmus of the operator to update the operator's name.
  # This is called in an `after_save` to keep the name of the operator in the fmu's geojson property in sync
  def update_operator_name_on_fmus
    fmus.find_each(&:save)
  end

  def recalculate_scores
    ScoreOperatorDocument.recalculate!(self)
  end

  def clean_document_cache
    # TODO: try different technique for jsonapi cache invalidation, this is undocumented way for cleaning cache of jsonapi resources
    Rails.cache.delete_matched(/operator_documents\/(#{operator_document_ids.join('|')})\//)
    Rails.cache.delete_matched(/operator_document_histories\/(#{operator_document_history_ids.join('|')})\//)
  end

  def refresh_ranking
    RankingOperatorDocument.refresh_for_country(country)
  end

  # rubocop:disable Rails/SkipsModelValidations
  def create_operator_id
    if country_id.present?
      update_columns(operator_id: "#{country.iso}-unknown-#{id}")
    else
      update_columns(operator_id: "na-unknown-#{id}")
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  def create_documents
    return if fa_id.blank? || country_id.blank?

    country = RequiredOperatorDocument.where(country_id: country_id).any? ? country_id : nil

    if operator_document_countries.none?
      RequiredOperatorDocumentCountry.where(country_id: country).find_each do |rodc|
        OperatorDocumentCountry.where(required_operator_document_id: rodc.id, operator_id: id).first_or_create do |odc|
          odc.update!(status: OperatorDocument.statuses[:doc_not_provided])
        end
      end
    end

    if operator_document_fmus.none?
      fmu_operators.each(&:update_documents_list)
    end
  end
end
