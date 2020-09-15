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
#  attachment                    :string
#  current                       :boolean
#  deleted_at                    :datetime
#  uploaded_by                   :integer          not null
#  user_id                       :integer
#  reason                        :text
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean          default("true"), not null
#  source                        :integer          default("1"), not null
#  source_info                   :string
#

require 'rails_helper'

RSpec.describe OperatorDocumentFmu, type: :model do
  subject(:operator_document_fmu) { FactoryBot.create(:operator_document_fmu) }

  it 'is valid with valid attributes' do
    expect(operator_document_fmu).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:required_operator_document_fmu)
      .with_foreign_key('required_operator_document_id')
      .required
    }
    it { is_expected.to belong_to(:fmu).required }
  end
end
