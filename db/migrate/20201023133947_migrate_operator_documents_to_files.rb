class MigrateOperatorDocumentsToFiles < ActiveRecord::Migration[5.0]
  def change
    DocumentMigrationService.new(:attachments).call
  end
end
