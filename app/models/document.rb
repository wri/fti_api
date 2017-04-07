# frozen_string_literal: true

# == Schema Information
#
# Table name: documents
#
#  id               :integer          not null, primary key
#  name             :string
#  document_type    :string
#  attachment       :string
#  attacheable_id   :integer
#  attacheable_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Document < ApplicationRecord
  mount_uploader :attachment, DocumentUploader

  belongs_to :attacheable, polymorphic: true

  after_destroy :remove_attachment_id_directory

  validates :document_type, presence: true, inclusion: { in: %w(Report Doumentation),
                                                         message: "%{value} is not a valid document type" }

  scope :by_report,        -> { where(document_type: 'Report') }
  scope :by_documentation, -> { where(document_type: 'Doumentation')   }

  class << self
    def types
      %w(Report Doumentation).freeze
    end

    def types_select
      types.map { |t| [I18n.t("document_types.#{t}", default: t), t.camelize] }
    end
  end

  def remove_attachment_id_directory
    FileUtils.rm_rf(File.join('public', 'uploads', 'document', 'attachment', self.id.to_s)) if self.attachment
  end
end
