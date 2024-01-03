# rubocop:disable all
class ChangeUploadedByInOperatorDocument < ActiveRecord::Migration[5.0]
  def change
    change_column_null :operator_documents, :uploaded_by, false, 4
  end
end
