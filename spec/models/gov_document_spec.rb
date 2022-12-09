# == Schema Information
#
# Table name: gov_documents
#
#  id                       :integer          not null, primary key
#  status                   :integer          not null
#  reason                   :text
#  start_date               :date
#  expire_date              :date
#  current                  :boolean          not null
#  uploaded_by              :integer
#  link                     :string
#  value                    :string
#  units                    :string
#  deleted_at               :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  required_gov_document_id :integer
#  country_id               :integer
#  user_id                  :integer
#
require 'rails_helper'

RSpec.describe GovDocument, type: :model do
  describe 'Class methods' do
    describe '#expire_documents' do
      let!(:gd) {
        create(
          :gov_document,
          force_status: status,
          expire_date: expire_date
        )
      }

      subject { GovDocument.expire_documents }

      context 'when the date is in the past' do
        let(:expire_date) { Date.today - 1.year }

        context 'when the status is valid' do
          let(:status) { :doc_valid }

          it { expect { subject }.to change { gd.reload.status }.from('doc_valid').to('doc_expired') }
        end

        context 'when the status is not required' do
          let(:status) { :doc_not_required }

          it 'destroys old document, generates a new not provided one' do
            expect { subject }.to \
              change { GovDocument.unscoped.count }.by(1).and \
              change { gd.reload.deleted? }.from(false).to(true).and \
              change { gd.current }.from(true).to(false)

            current_doc = GovDocument.find_by(required_gov_document: gd.required_gov_document, current: true)
            expect(current_doc.status).to eq('doc_not_provided')
          end
        end

        context 'when the status is pending' do
          let(:status) { :doc_pending }

          it { expect { subject }.to_not change { gd.reload.status } }
        end

      end
      context 'when the date is in the future' do
        let(:expire_date) { Date.today + 1.year }
        let(:status) { :doc_valid }

        it { expect { subject }.to_not change { gd.reload.status } }
      end
    end
  end
end
