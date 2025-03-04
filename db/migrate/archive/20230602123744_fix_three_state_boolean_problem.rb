# rubocop:disable all
class FixThreeStateBooleanProblem < ActiveRecord::Migration[7.0]
  def change
    change_column_null :api_keys, :is_active, false, false
    change_column_null :country_links, :active, false, true
    change_column_null :country_vpas, :active, false, true
    change_column_null :fmus, :certification_fsc, false, false
    change_column_null :fmus, :certification_pefc, false, false
    change_column_null :fmus, :certification_olb, false, false
    change_column_null :fmus, :certification_pafc, false, false
    change_column_null :fmus, :certification_fsc_cw, false, false
    change_column_null :fmus, :certification_tlv, false, false
    change_column_null :fmus, :certification_ls, false, false
    change_column_null :governments, :is_active, false, false
    change_column_null :observation_histories, :is_active, false, false
    change_column_null :observation_histories, :hidden, false, false
    change_column_null :observation_statistics, :is_active, false, false
    change_column_null :observation_statistics, :hidden, false, false
    change_column_null :observations, :is_active, false, false
    change_column_null :observations, :is_physical_place, false, false
    change_column_null :observations, :hidden, false, false
    change_column_null :observers, :is_active, false, false
    change_column_null :observers, :public_info, false, false
    change_column_null :operator_document_histories, :public, false, false
    change_column_null :operators, :is_active, false, false
    change_column_null :subcategories, :location_required, false, false
    change_column_null :users, :is_active, false, false

    change_column_default :fmu_operators, :current, from: nil, to: false
    change_column_default :observation_histories, :is_active, from: nil, to: false
    change_column_default :observation_histories, :hidden, from: nil, to: false
    change_column_default :observation_statistics, :is_active, from: nil, to: false
    change_column_default :observation_statistics, :hidden, from: nil, to: false
    change_column_default :operator_document_histories, :public, from: nil, to: false
  end
end
