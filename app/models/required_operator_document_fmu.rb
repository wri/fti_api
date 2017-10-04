# == Schema Information
#
# Table name: required_operator_documents
#
#  id                                  :integer          not null, primary key
#  type                                :string
#  required_operator_document_group_id :integer
#  name                                :string
#  country_id                          :integer
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  valid_period                        :integer
#  deleted_at                          :datetime
#

class RequiredOperatorDocumentFmu < RequiredOperatorDocument
  has_many :operator_document_fmus

  after_create :create_operator_document_fmus

  def create_operator_document_fmus
    Fmu.where(country_id: self.country_id).find_each do |fmu|
      if fmu.operator_id.present? # This is to prevent faulty situations when the fmu has no operator id
        OperatorDocumentFmu.where(required_operator_document_id: self.id,
                                  operator_id: fmu.operator_id,
                                  fmu_id: fmu.id).first_or_create do |odf|
          odf.update_attributes!(status: OperatorDocument.statuses[:doc_not_provided])
        end
      end
    end
  end
end
