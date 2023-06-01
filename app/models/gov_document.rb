# frozen_string_literal: true

# == Schema Information
#
# Table name: gov_documents
#
#  id                       :integer          not null, primary key
#  status                   :integer          not null
#  start_date               :date
#  expire_date              :date
#  uploaded_by              :integer
#  link                     :string
#  value                    :string
#  units                    :string
#  deleted_at               :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  required_gov_document_id :integer          not null
#  country_id               :integer          not null
#  user_id                  :integer
#  attachment               :string
#

class GovDocument < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  enum status: {doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4}
  enum uploaded_by: {government: 1, admin: 2}

  belongs_to :user, optional: true
  belongs_to :country
  belongs_to :required_gov_document, -> { with_archived }, inverse_of: :gov_documents

  mount_base64_uploader :attachment, GovDocumentUploader
  include MoveableAttachment

  before_validation :set_expire_date, if: proc { |d| d.required_gov_document.valid_period? }
  before_validation :clear_wrong_fields
  before_validation :set_status, on: :create
  before_validation :set_country, on: :create

  validates :start_date, presence: true, if: proc { |d| d.required_gov_document.valid_period? && d.has_data? }
  validates :expire_date, presence: true, if: proc { |d| d.required_gov_document.valid_period? && d.has_data? }

  after_update :move_previous_attachment_to_private_directory, if: :saved_change_to_attachment?

  after_destroy :move_attachment_to_private_directory
  after_restore :move_attachment_to_public_directory

  scope :with_archived, -> { unscope(where: :deleted_at) }
  scope :to_expire, ->(date) { where("expire_date < ?", date).where(status: EXPIRABLE_STATUSES) }
  scope :valid, -> { actual.where(status: GovDocument.statuses[:doc_valid]) }

  EXPIRABLE_STATUSES = %w[doc_valid]

  def set_expire_date
    self.expire_date = begin
      start_date + required_gov_document.valid_period.days
    rescue
      nil
    end
  end

  def self.expire_documents
    documents_to_expire = GovDocument.to_expire(Time.zone.today)
    number_of_documents = documents_to_expire.count
    documents_to_expire.find_each(&:expire_document)
    Rails.logger.info "Expired #{number_of_documents} government documents"
  end

  def expire_document
    update!(status: "doc_expired")
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
    self.status = GovDocument.statuses[:doc_not_provided]
  end

  def set_country
    self.country_id = required_gov_document.country_id
  end

  def move_previous_attachment_to_private_directory
    previous_attachment_filename = previous_changes[:attachment][0]
    return if previous_attachment_filename.blank?

    from = File.join(attachment.root, attachment.store_dir, previous_attachment_filename)
    to = from.gsub("/public/", "/private/")
    FileUtils.makedirs(File.dirname(to))
    system "mv #{Shellwords.escape(from)} #{Shellwords.escape(to)}"
  end

  # we only want to move current attachment back to public directory
  def move_attachment_to_public_directory
    attachment_attr = self[:attachment]
    return if attachment_attr.nil?

    to = File.join(attachment.root, attachment.store_dir, attachment_attr)
    from = to.gsub("/public/", "/private/")
    FileUtils.makedirs(File.dirname(from))
    system "mv #{Shellwords.escape(from)} #{Shellwords.escape(to)}"
  end

  def clear_wrong_fields
    case required_gov_document.document_type
    when "file"
      self.link = self.value = self.units = nil
    when "link"
      self.value = self.units = nil
      remove_attachment!
    when "stats"
      remove_attachment!
    end
  end
end
