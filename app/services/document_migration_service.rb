# frozen_string_literal: true

class DocumentMigrationService
  def initialize(*args)
    args.map!(&:to_sym)
    @attachments = args.include? :attachments
    @documents = args.include? :documents
  end

  def call
    migrate_attachments
    migrate_documents
  end

  private

  # Migrates the attachments in OperatorDocument to an external class: DocumentFile
  def migrate_attachments
    return unless @attachments

    OperatorDocument.where.not(attachment: nil).find_each.with_index do |od, i|
      Rails.logger.info "Migrated #{i} documents" if i % 10
      df = DocumentFile.create! file_name: od.attachment_identifier.split('.').first, attachment: od.attachment
      # rubocop:disable Rails/SkipsModelValidations
      od.update_column :document_file_id, df.id
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  # Creates anOperatorDocumentHistory for each OperatorDocument
  # and deletes the ones that aren't active
  def migrate_documents
    return unless @documents

    # TODO Finish this
    OperatorDocument.find_each do |od|
      od.create_history
    end
  end
end
