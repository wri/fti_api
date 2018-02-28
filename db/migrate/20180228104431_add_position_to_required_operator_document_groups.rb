class AddPositionToRequiredOperatorDocumentGroups < ActiveRecord::Migration[5.0]
  def change
    add_column :required_operator_document_groups, :position, :integer
  end
end
