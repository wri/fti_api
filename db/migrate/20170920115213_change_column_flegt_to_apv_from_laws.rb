class ChangeColumnFlegtToApvFromLaws < ActiveRecord::Migration[5.0]
  def change
    rename_column :laws, :flegt, :apv
  end
end
