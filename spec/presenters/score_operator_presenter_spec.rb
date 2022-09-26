require 'rails_helper'

RSpec.describe ScoreOperatorPresenter do
  before :all do
    country = create(:country)
    operator = create(:operator, country: country, fa_id: 'fa-id')

    required_operator_document_group = create(:required_operator_document_group)

    fmu = create(:fmu, country: country, forest_type: 'vdc')
    fmu2 = create(:fmu, country: country, forest_type: 'ufa')
    create(:fmu_operator, fmu: fmu, operator: operator)
    create(:fmu_operator, fmu: fmu2, operator: operator)

    required_operator_document_data = {
      country: country,
      required_operator_document_group: required_operator_document_group
    }
    create(:required_operator_document_country, country: country, contract_signature: true)

    create_list(:required_operator_document_country, 4, **required_operator_document_data)
    create_list(
      :required_operator_document_fmu,
      4,
      forest_types: [Fmu::FOREST_TYPES[:vdc][:index], Fmu::FOREST_TYPES[:ufa][:index]],
      **required_operator_document_data
    )

    # now operator has 4 docs, one contract
    c1, c2, c3, c4 = operator.operator_documents.non_signature.country_type
    f1, f2, f3, f4 = operator.operator_documents.non_signature.fmu_type.where(fmu_id: fmu.id)
    f21, f22, f23, f24 = operator.operator_documents.non_signature.fmu_type.where(fmu_id: fmu2.id)

    c1.update(public: false, status: 'doc_valid')
    c2.update(public: true, status: 'doc_valid')
    c3.update(public: true, status: 'doc_not_provided')
    c4.update(public: true, status: 'doc_not_required')

    f1.update(public: false, status: 'doc_valid')
    f2.update(public: true, status: 'doc_valid')
    f3.update(public: true, status: 'doc_not_provided')
    f4.update(public: false, status: 'doc_not_required')

    f21.update(public: false, status: 'doc_expired')
    f22.update(public: true, status: 'doc_pending')
    f23.update(public: true, status: 'doc_valid')
    f24.update(public: false, status: 'doc_invalid')

    @operator = operator
  end

  context 'publication authorization signed' do
    before :context do
      @operator.operator_documents.signature.first.update(status: 'doc_valid')
    end

    subject { ScoreOperatorPresenter.new(@operator.operator_documents) }

    describe 'all' do
      it 'returns score for all documents' do
        # valid / total - not_required
        expect(subject.all).to eq(5.0 / 10.0)
      end
    end

    describe 'fmu' do
      it 'returns score for fmu documents' do
        expect(subject.fmu).to eq(3.0 / 7.0)
      end
    end

    describe 'country' do
      it 'returns score for country documents' do
        expect(subject.country).to eq(2.0 / 3.0)
      end
    end

    describe 'total' do
      it 'returns total number of documents' do
        expect(subject.total).to eq(12)
      end
    end

    describe 'summary public' do
      it 'returns public summary' do
        expect(subject.summary_public).to eq({
          doc_not_provided: 2 + 1 + 1, # public not provided = not_provided + pending + invalid
          doc_valid: 5,
          doc_expired: 1,
          doc_not_required: 2
        })
      end
    end

    describe 'summary private' do
      it 'returns private summary' do
        expect(subject.summary_private).to eq({
          doc_not_provided: 2,
          doc_pending: 1,
          doc_invalid: 1,
          doc_valid: 5,
          doc_expired: 1,
          doc_not_required: 2
        })
      end
    end
  end

  context 'publication authorization not signed' do
    before :context do
      @operator.operator_documents.signature.first.update(status: 'doc_invalid')
    end

    subject { ScoreOperatorPresenter.new(@operator.operator_documents) }

    describe 'all' do
      it 'returns score for all documents' do
        # public_valid / total - public_not_required
        expect(subject.all).to eq(3.0 / (12.0 - 1))
      end
    end

    describe 'fmu' do
      it 'returns score for fmu documents' do
        # public_valid / total_fmu - public_fmu_not_required
        expect(subject.fmu).to eq(2.0 / 8.0)
      end
    end

    describe 'country' do
      it 'returns score for country documents' do
        # public_valid / total_country - public_country_not_required
        expect(subject.country).to eq(1.0 / 3.0)
      end
    end

    describe 'total' do
      it 'returns total number of documents' do
        expect(subject.total).to eq(12)
      end
    end

    describe 'summary public' do
      it 'returns public summary' do
        expect(subject.summary_public).to eq({
          doc_not_provided: 2 + 1 + 1 + 4, # public not provided = not_provided + pending + invalid + private_valid_expired_not_required
          doc_valid: 3,
          doc_expired: 0,
          doc_not_required: 1
        })
      end
    end

    describe 'summary private' do
      it 'returns private summary' do
        expect(subject.summary_private).to eq({
          doc_not_provided: 2,
          doc_pending: 1,
          doc_invalid: 1,
          doc_valid: 5,
          doc_expired: 1,
          doc_not_required: 2
        })
      end
    end
  end
end
