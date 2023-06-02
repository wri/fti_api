# == Schema Information
#
# Table name: operator_document_histories
#
#  id                            :integer          not null, primary key
#  type                          :string
#  expire_date                   :date
#  start_date                    :date
#  status                        :integer
#  uploaded_by                   :integer
#  reason                        :text
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean          default(FALSE), not null
#  source                        :integer
#  source_info                   :string
#  fmu_id                        :integer
#  document_file_id              :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  operator_document_id          :integer
#  operator_id                   :integer
#  user_id                       :integer
#  required_operator_document_id :integer
#  deleted_at                    :datetime
#  operator_document_updated_at  :datetime         not null
#  operator_document_created_at  :datetime         not null
#
require "rails_helper"

RSpec.describe OperatorDocumentHistory, type: :model do
  describe "Existence" do
    let!(:od) { create(:operator_document_country) }
    context "Creating an OperatorDocument" do
      it "Adds an OperatorDocumentHistory" do
        odh = OperatorDocumentHistory.find_by(operator_document_id: od.id)
        expect(odh).not_to be_nil
        expect(odh.type).to eql(od.type + "History")
        expect(odh.expire_date).to eql(od.expire_date)
        expect(odh.start_date).to eql(od.start_date)
        expect(odh.uploaded_by).to eql(od.uploaded_by)
        expect(odh.reason).to eql(od.reason)
        expect(odh.note).to eql(od.note)
        expect(odh.response_date).to eql(od.response_date)
        expect(odh.public).to eql(od.public)
        expect(odh.source).to eql(od.source)
        expect(odh.source_info).to eql(od.source_info)
        expect(odh.fmu_id).to eql(od.fmu_id)
        expect(odh.document_file_id).to eql(od.document_file_id)
        expect(odh.operator_document_created_at.to_i).to eql(od.created_at.to_i)
        expect(odh.operator_document_updated_at.to_i).to eql(od.updated_at.to_i)
        expect(odh.operator_id).to eql(od.operator_id)
        expect(odh.user_id).to eql(od.user_id)
        expect(odh.required_operator_document_id).to eql(od.required_operator_document_id)
      end
    end
    context "Updating an OperatorDocument" do
      it "Adds a new version of the OperatorDocumentHistory" do
        od.update(note: "new note")
        od.reload
        odhs = OperatorDocumentHistory.where(operator_document_id: od.id).order({operator_document_updated_at: :desc})
        expect(odhs.count).to eql(2)
        expect(odhs.first.note).to eql("new note")
        expect(odhs.first.operator_document_updated_at.to_i).to eql(od.updated_at.to_i)
        expect(odhs.first.operator_document_created_at.to_i).to eql(od.created_at.to_i)
        expect(odhs.last.note).to be_nil
      end
    end
    context "Deletes an OperatorDocument" do
      it "Adds a new version of OperatorDocumentHistory and keeps the file" do
        document_file = od.document_file
        od.destroy
        od.reload
        odhs = OperatorDocumentHistory.where(operator_document_id: od.id).order({operator_document_updated_at: :desc})
        expect(odhs.count).to eql(2)
        expect(odhs.first.status).to eql("doc_not_provided")
        expect(odhs.last.document_file_id).to eql(document_file.id)
        expect(document_file.attachment).not_to be_nil
      end
    end
  end
end
