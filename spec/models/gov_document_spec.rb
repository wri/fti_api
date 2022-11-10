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

          it { expect { subject }.to change { gd.reload.status }.from('doc_not_required').to('doc_expired') }
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
