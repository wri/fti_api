# rubocop:disable all
class RemoveInstitutionFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :institution, :string
  end
end
