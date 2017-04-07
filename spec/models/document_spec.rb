# == Schema Information
#
# Table name: documents
#
#  id               :integer          not null, primary key
#  name             :string
#  document_type    :string
#  attachment       :string
#  attacheable_id   :integer
#  attacheable_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

RSpec.describe Document, type: :model do
  before :each do
    @document = create(:document)
  end

  it 'Count on law' do
    expect(Document.count).to eq(1)
    expect(@document.attacheable.illegality).to eq('Illegality one')
  end

  it 'Document type validation' do
    @document = Document.new(document_type: '')

    @document.valid?
    expect { @document.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Document type can't be blank, Document type  is not a valid document type")
  end

  it 'Document types' do
    expect(Document.types).to eq(['Report', 'Doumentation'])
  end

  it 'Document type select' do
    expect(Document.types_select).to eq([['Report', 'Report'], ['Doumentation', 'Doumentation']])
  end
end
