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
  has_paper_trail
  acts_as_paranoid

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4 }
  enum uploaded_by: { government: 1, admin: 2 }

  belongs_to :country
  belongs_to :required_gov_document, -> { with_archived }

  mount_base64_uploader :attachment, GovDocumentUploader
  include MoveableAttachment

  before_validation :set_expire_date, if: Proc.new { |d| d.required_gov_document.valid_period? }
  before_validation :clear_wrong_fields
  before_validation :set_status, on: :create
  before_validation :set_country, on: :create

  validates_presence_of :start_date, if: Proc.new { |d| d.required_gov_document.valid_period? && d.has_data? }
  validates_presence_of :expire_date, if: Proc.new { |d| d.required_gov_document.valid_period? && d.has_data? }

  after_create :update_percentages
  after_update :update_percentages, if: :saved_change_to_status?

  after_update :move_previous_attachment_to_private_folder, if: :saved_change_to_attachment?

  scope :with_archived, -> { unscope(where: :deleted_at) }
  scope :to_expire, ->(date) {
    where('expire_date < ?', date)
      .where(status: EXPIRABLE_STATUSES)
  }
  scope :valid,        -> { actual.where(status: GovDocument.statuses[:doc_valid]) }
  scope :required,     -> { actual.where.not(status: GovDocument.statuses[:doc_not_required]) }

  EXPIRABLE_STATUSES = %w[doc_valid doc_not_required]

  def update_percentages
    required_gov_document.country.update_valid_documents_percentages
  end

  def set_expire_date
    self.expire_date = start_date + required_gov_document.valid_period.days rescue nil
  end

  def self.expire_documents
    documents_to_expire = GovDocument.to_expire(Date.today)
    number_of_documents = documents_to_expire.count
    documents_to_expire.find_each(&:expire_document)
    Rails.logger.info "Expired #{number_of_documents} government documents"
  end

  def expire_document
    reset_to_not_provided! if status == 'doc_not_required'
    update!(status: 'doc_expired') if status == 'doc_valid'
  end

  def has_data?
    attachment.present? || link.present? || (value.present? && units.present?)
  end

  def reset_to_not_provided!
    remove_attachment!
    update!(
      status: OperatorDocument.statuses[:doc_not_provided],
      expire_date: nil, start_date: nil, uploaded_by: nil, user_id: nil,
      value: nil, link: nil
    )
  end

  private

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

  def move_previous_attachment_to_private_folder
    previous_attachment_filename = previous_changes[:attachment][0]
    return if previous_attachment_filename.blank?

    from = File.join(attachment.root, attachment.store_dir, previous_attachment_filename)
    to = from.gsub('/public/', '/private/')
    FileUtils.makedirs(File.dirname(to))
    system "mv #{Shellwords.escape(from)} #{Shellwords.escape(to)}"
  end

  def clear_wrong_fields
    case required_gov_document.document_type
    when 'file'
      self.link = self.value = self.units = nil
    when 'link'
      self.value = self.units = nil
      self.attachment = nil # TODO
    when 'stats'
      self.link = nil
      self.attachment = nil # TODO
    end
  end
end
