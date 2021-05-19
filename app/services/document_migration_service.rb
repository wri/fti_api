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

  # Creates an OperatorDocumentHistory for the last current version of the operator document
  # and deletes the ones that aren't current but do have a current version with an existing OperatorDocumentHistory
  #
  # rubocop:disable Rails/Output
  def migrate_documents
    return unless @documents

    not_to_destroy = []
    currents = []

    operator_documents_unscoped = OperatorDocument.unscoped

    puts "operator_documents_unscoped.count >> #{operator_documents_unscoped.count}"
    puts "OperatorDocumentHistory >> #{OperatorDocumentHistory.all.count}"

    operator_documents_unscoped.find_each do |od|
      current = operator_documents_unscoped.where(current: true, operator_id: od.operator_id,
                                                  required_operator_document_id: od.required_operator_document_id,
                                                  fmu_id: od.fmu_id).order(updated_at: :desc)

      if current.none?
        not_to_destroy.push(od.id)
      else
        currents.push(current.first.id)
      end
    end

    puts "currents.uniq.count >> #{currents.uniq.count}"
    puts "not_to_destroy.count >> #{not_to_destroy.count}"

    currents.uniq.each do |operator_document_id|
      unless OperatorDocumentHistory.where(operator_document_id: operator_document_id).any?
        history = operator_documents_unscoped.find(operator_document_id)&.create_history
        not_to_destroy.push(operator_document_id) unless history.persisted?
      end
    end

    operator_documents_destroyable = operator_documents_unscoped.where.not(current: true, id: not_to_destroy)

    operator_documents_destroyable.each do |od|
      AnnexDocument.where(documentable_type: 'OperatorDocument', documentable_id: od.id).delete_all
    end

    operator_documents_destroyable.delete_all
  end
  # rubocop:enable Rails/Output
end
