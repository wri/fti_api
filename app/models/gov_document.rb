# frozen_string_literal: true
# == Schema Information
#
# Table name: gov_documents
#
#  id                       :integer          not null, primary key
#  status                   :integer          not null
#  reason                   :text
#  start_date               :date
#  expire_date              :date
#  current                  :boolean          not null
#  uploaded_by              :integer
#  link                     :string
#  value                    :string
#  units                    :string
#  deleted_at               :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  required_gov_document_id :integer
#  country_id               :integer
#  user_id                  :integer
#

class GovDocument < ApplicationRecord
  acts_as_paranoid

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4, doc_not_required: 5 }
  enum uploaded_by: { operator: 1, monitor: 2, admin: 3, other: 4 }

  belongs_to :required_gov_document, ->() { with_archived }, required: true
  has_many :gov_files
  accepts_nested_attributes_for :gov_files

  before_validation :set_expire_date, if: Proc.new { |d| d.required_gov_document.valid_period? }
  before_validation :clear_wrong_fields

  validates_presence_of :start_date, if: Proc.new { |d| d.required_gov_document.valid_period? && d.has_data? }
  validates_presence_of :expire_date, if: Proc.new { |d| d.required_gov_document.valid_period? && d.has_data? }

  before_save :update_current, on: %w[create update], if: :current_changed?
  before_create :set_status
  before_create :set_country
  before_create :delete_previous_pending_document
  after_save :update_percentages, on: %w[create update],  if: :status_changed?

  before_destroy :insure_unity

  scope :with_archived, ->() { unscope(where: :deleted_at) }
  scope :to_expire, ->(date) { where("expire_date < '#{date}'::date and status = #{GovDocument.statuses[:doc_valid]}") }
  scope :actual,       -> { where(current: true, deleted_at: nil) }
  scope :valid,        -> { actual.where(status: GovDocument.statuses[:doc_valid]) }
  scope :required,     -> { actual.where.not(status: GovDocument.statuses[:doc_not_required]) }

  def update_percentages
    required_gov_document.country.update_valid_documents_percentages
  end

  def set_expire_date
    self.expire_date = start_date + required_gov_document.valid_period.days rescue nil
  end

  def update_current
    if current == true
      documents_to_update = GovDocument.where(required_gov_document_id: required_gov_document_id,
                                              current: true)
                              .where.not(id: id)
      documents_to_update.find_each {|x| x.update_attributes!(current: false)}
    else
      documents_to_update = GovDocument.where(required_gov_document_id: required_gov_document_id, current: true)
      unless documents_to_update.any?
        self.update_attributes(current: false)
      end
    end
  end

  def self.expire_documents
    documents_to_expire = GovDocument.to_expire(Date.today)
    number_of_documents = documents_to_expire.count
    documents_to_expire.find_each(&:expire_document)
    Rails.logger.info "Expired #{number_of_documents} government documents"
  end

  def expire_document
    self.update_attributes(status: GovDocument.statuses[:doc_expired])
  end

  def has_data?
    gov_files.any? || link.present? || (value.present? && units.present?) || reason.present?
  end


  private

  def insure_unity
    return if required_gov_document&.marked_for_destruction?
    doc = GovDocument.new(required_gov_document_id: required_gov_document_id,
                          status: GovDocument.statuses[:doc_not_provided],
                          current: true)
    doc.save!(validate: false)
  end

  def set_status
    if has_data?
      self.status = GovDocument.statuses[:doc_pending]
    else
      self.status = GovDocument.statuses[:doc_not_provided]
    end
  end

  def set_country
    self.country_id = required_gov_document.country_id
  end

  def delete_previous_pending_document
    pending_documents = GovDocument.where(required_gov_document_id: required_gov_document_id,
                                          status: GovDocument.statuses[:doc_pending])
    pending_documents.each { |x| x.destroy }
  end

  def clear_wrong_fields
    if reason.present?
      self.link = self.value = self.units = nil
      self.gov_files.each(&:really_destroy!)
      return
    end

    case required_gov_document.document_type
    when 'file'
      self.link = self.value = self.units = nil
    when 'link'
      self.value = self.units = nil
      self.gov_files.each(&:really_destroy!)
    when 'stats'
      self.link = nil
      self.gov_files.each(&:really_destroy!)
    end
  end
end
