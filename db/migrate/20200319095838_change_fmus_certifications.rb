class ChangeFmusCertifications < ActiveRecord::Migration[5.0]
  def change
    rename_column :fmus, :certification_tltv, :certification_tlv
    rename_column :fmus,:certification_vlc, :certification_pafc
    rename_column :fmus, :certification_vlo, :certification_fsc_cw

    change_column_default :fmus, :certification_tlv, false
    change_column_default :fmus, :certification_pafc, false
    change_column_default :fmus, :certification_fsc_cw, false

    add_column :fmus, :certification_ls, :boolean, default: false
  end
end
