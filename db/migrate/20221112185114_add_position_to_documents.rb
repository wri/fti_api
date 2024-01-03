# rubocop:disable all
class AddPositionToDocuments < ActiveRecord::Migration[5.1]
  def change
    add_column :required_operator_documents, :position, :integer
    add_column :required_gov_documents, :position, :integer

    RequiredOperatorDocument.group(:country_id).pluck(:country_id).each do |country_id|
      RequiredOperatorDocumentGroup.find_each do |rodg|
        RequiredOperatorDocument
          .with_translations
          .where(country_id: country_id, required_operator_document_group: rodg)
          .order(:name)
          .each.with_index do |rod, index|
          rod.update_column(:position, index + 1)
        end
      end
    end

    RequiredGovDocument.group(:country_id).pluck(:country_id).each do |country_id|
      RequiredGovDocumentGroup.find_each do |rgdg|
        RequiredGovDocument
          .with_translations
          .where(country_id: country_id, required_gov_document_group: rgdg)
          .order(:name)
          .each.with_index do |rgd, index|
          rgd.update_column(:position, index + 1)
        end
      end
    end

    add_index :required_operator_documents,
      [:country_id, :required_operator_document_group_id, :position],
      name: "index_rod_on_country_id_and_rodg_id_and_position"
    add_index :required_gov_documents,
      [:country_id, :required_gov_document_group_id, :position],
      name: "index_rgd_on_country_id_and_rgdg_id_and_position"
  end
end
