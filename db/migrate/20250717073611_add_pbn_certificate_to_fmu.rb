class AddPbnCertificateToFmu < ActiveRecord::Migration[7.2]
  def change
    add_column :fmus, :certification_pbn, :boolean, default: false, null: false
  end
end
