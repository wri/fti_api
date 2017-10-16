class AddIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :countries, :is_active
    add_index :countries, :iso

    # TODO Add this in another migration after merging the branches
    # add_index :fmu_operators, :current

    add_index :laws, :country_id
    add_index :laws, :subcategory_id

    add_index :observation_documents, :name
    add_index :observation_documents, :observation_id
    add_index :observation_documents, :user_id

    add_index :observation_report_observers, [:observation_report_id, :observer_id], name: 'index_obs_rep_id_and_observer_id'
    add_index :observation_report_observers, [:observer_id, :observation_report_id], name: 'index_observer_id_and_obs_rep_id'

    add_index :observation_reports, :title
    add_index :observation_reports, :user_id

    add_index :observations, :is_active
    add_index :observations, :fmu_id
    add_index :observations, :law_id
    add_index :observations, :observation_report_id
    add_index :observations, :observation_type
    add_index :observations, :user_id
    add_index :observations, :validation_status

    add_index :observers, :is_active

    add_index :operator_documents, :current
    add_index :operator_documents, :fmu_id
    add_index :operator_documents, :operator_id
    add_index :operator_documents, :required_operator_document_id
    add_index :operator_documents, :status
    add_index :operator_documents, :type
    add_index :operator_documents, :start_date
    add_index :operator_documents, :expire_date

    add_index :operators, :fa_id
    add_index :operators, :is_active

    add_index :required_operator_documents, :required_operator_document_group_id, name: 'index_req_op_doc_group_id'
    add_index :required_operator_documents, :type

    add_index :severities, [:level, :subcategory_id]
    add_index :severities, [:subcategory_id, :level]

    add_index :subcategories, :category_id
    add_index :subcategories, :subcategory_type

  end
end
