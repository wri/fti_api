# == Schema Information
#
# Table name: operator_documents
#
#  id                            :integer          not null, primary key
#  type                          :string
#  expire_date                   :date
#  start_date                    :date
#  fmu_id                        :integer
#  required_operator_document_id :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  status                        :integer
#  operator_id                   :integer
#  deleted_at                    :datetime
#  uploaded_by                   :integer
#  user_id                       :integer
#  reason                        :text
#  response_date                 :datetime
#  public                        :boolean          default(TRUE), not null
#  source                        :integer          default("company")
#  source_info                   :string
#  document_file_id              :integer
#  admin_comment                 :text
#

require "rails_helper"

RSpec.describe OperatorDocumentFmu, type: :model do
  subject(:operator_document_fmu) { FactoryBot.create(:operator_document_fmu) }

  it "is valid with valid attributes" do
    expect(operator_document_fmu).to be_valid
  end
end
