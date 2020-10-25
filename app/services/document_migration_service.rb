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

    not_to_destroy = []
    OperatorDocument.unscoped.find_each do |od|
      current = OperatorDocument.unscoped.where(current: true, operator_id: od.operator_id,
                                                required_operator_document_id: od.required_operator_document_id,
                                                fmu_id: od.fmu_id)

      if current.none?
        params = { 'operator_document_id' => od.id }
        not_to_destroy << od.id
      else
        params = { 'operator_document_id' => current.first.id }
      end

      history = od.create_history(params)
      unless history.persisted?
        Rails.logger.warn "Couldn't create history for document #{od.id}"
        not_to_destroy << od.id
        next
      end
      next if od.operator_document_annexes.none?

      update_annexes od, history
    end
    OperatorDocument.unscoped.where.not(current: true, id: not_to_destroy).delete_all
  end

  private

  def update_annexes(document, history)
    document.operator_document_annexes.update_all documentable_type: 'OperatorDocumentHistory', documentable_id: history.id
  end
end
