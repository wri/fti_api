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
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean          default("true"), not null
#  source                        :integer          default("1")
#  source_info                   :string
#  document_file_id              :integer
#

require 'rails_helper'

RSpec.describe OperatorDocument, type: :model do
  subject(:operator_document) { FactoryBot.build(:operator_document) }

  it 'is valid with valid attributes' do
    expect(operator_document).to be_valid
  end

  describe 'Validations' do
    describe '#start_date' do
      context 'has an attachment' do
        before { allow(subject).to receive(:attachment?).and_return(true) }
        it { is_expected.to validate_presence_of(:start_date) }
      end

      context 'has not an attachment' do
        before { allow(subject).to receive(:attachment?).and_return(false) }
        it { is_expected.not_to validate_presence_of(:start_date) }
      end
    end

    describe '#set_expire_date' do
      context 'when there is not expire_date' do
        it 'set expire_date with the start_date plus the valid_period days' do
          operator_document = build(:operator_document, expire_date: nil)
          operator_document.valid?

          expect(operator_document.expire_date).to eql(
            operator_document.start_date +
              operator_document.required_operator_document.valid_period.days
          )
        end
      end
    end

    describe '#reason_or_attachment' do
      context 'when there is attachment and reason' do
        it 'add an error on reason' do
          operator_document = build(:operator_document, reason: 'aaa')

          expect(operator_document.valid?).to eql false
          expect(operator_document.errors[:reason]).to eql(
            ['Cannot have a reason not to have a document']
          )
        end
      end
    end
  end

  describe 'Hooks' do
    before :all do
      @country = create(:country)
      @operator = create(:operator, country: @country, fa_id: 'fa_id')

      @fmu = create(:fmu, country: @country)
      create(:fmu_operator, fmu: @fmu, operator: @operator)
    end

    before do
      @required_operator_document = create(
        :required_operator_document,
        country: @country,
        required_operator_document_group: @required_operator_document_group)
    end

    describe '#update_current' do
      context 'when there is not operator or he/she is marked for destruction' do
        before do
          create(:operator_document,
                 operator: @operator,
                 required_operator_document: @required_operator_document,
                 fmu: @fmu,
                 current: true)

          @operator_document = build(
            :operator_document,
            operator: @operator,
            required_operator_document: @required_operator_document,
            fmu: @fmu)
        end

        context 'when operator_document is the current one' do
          it 'update related operator_document with current false' do
            @operator_document.save

            expect(@operator_document.current).to eql true
            OperatorDocument.where.not(id: @operator_document.id).each do |operator_document|
              expect(operator_document.current).to eql false
            end
          end
        end
      end
    end

    describe '#set_status' do
      context 'when attachment or reason are present' do
        it 'update status as doc_pending' do
          operator_document = create(:operator_document)

          expect(operator_document.status).to eql 'doc_pending'
        end
      end

      context 'when attachment or reason are not present' do
        it 'update status as doc_not_provided' do
          operator_document = create(:operator_document, attachment: nil, reason: nil)

          expect(operator_document.status).to eql 'doc_not_provided'
        end
      end
    end

    describe '#delete_previous_pending_document' do
      it 'deletes previous pending operator_documents' do
        another_operator = create(:operator, country: @country, fa_id: 'fa_id')
        create(
          :operator_document,
          operator: another_operator,
          fmu: @fmu,
          required_operator_document: @required_operator_document)

        create(
          :operator_document,
          operator: @operator,
          fmu: @fmu,
          required_operator_document: @required_operator_document)

        expect(OperatorDocument.all.size).to eql 2

        create(
          :operator_document,
          operator: @operator,
          fmu: @fmu,
          required_operator_document: @required_operator_document)

        expect(OperatorDocument.all.size).to eql 2
      end
    end

    describe '#update_operator_percentages' do
      before do
        valid_status = OperatorDocument.statuses[:doc_valid]
        pending_status = OperatorDocument.statuses[:doc_pending]
        common_data = {
          operator_id: @operator.id,
          current: true,
          required_operator_document_id: @required_operator_document.id,
          public: true
        }

        # Generate one valid operator document and two pending operator documents of each type
        valid_op_doc = create(:operator_document, **common_data)
        valid_op_doc.reload
        valid_op_doc.update_attributes(status: valid_status)
        @operator.reload

        pending_op_docs = create_list(:operator_document, 2, **common_data)
        pending_op_docs.each do |pending_op_doc|
          pending_op_doc.update_attributes(status: pending_status)
          @operator.reload
        end
      end

      it 'update valid operator percentages' do
        @operator.reload
        expect(@operator.score_operator_document.all.round(2)).to eql (1.0 / 3.0).round(2)

        operator_document = OperatorDocument.where(
          operator_id: @operator.id,
          required_operator_document_id: @required_operator_document.id,
          status: OperatorDocument.statuses[:doc_valid]
        ).first
        operator_document.update_attributes(status: OperatorDocument.statuses[:doc_not_required])

        @operator.reload
        expect(@operator.score_operator_document.all).to eql 0.0
      end
    end

    describe '#insure_unity' do
      context 'when operator and required_operator_document exist and are not marked '\
              'for destruction, not current operator document and not required operator document' do
        it 'creates a new operator document' do
          operator_document = create(
            :operator_document,
            operator: @operator,
            required_operator_document: @required_operator_document,
            current: true)

          expect(OperatorDocument.count).to eql 1

          operator_document.destroy

          expect(OperatorDocument.count).to eql 1
        end
      end
    end
  end

  describe 'Instance methods' do
    describe '#expire_document' do
      it 'update status as doc_expired' do
        operator_document = create(:operator_document)

        expect(operator_document.status).not_to eql 'doc_expired'

        operator_document.expire_document

        expect(operator_document.status).to eql 'doc_expired'
      end
    end
  end

  describe 'Class methods' do
    describe '#expire_documents' do
      it 'update status as doc_expired which expire_date is lower than today' do
        required_operator_document =
          create(:required_operator_document, contract_signature: false)
        create(
          :operator_document,
          required_operator_document: required_operator_document,
          status: OperatorDocument.statuses[:doc_valid],
          expire_date: Date.yesterday)

        OperatorDocument.expire_documents

        OperatorDocument.to_expire(Date.today).each do |operator_document|
          expect(operator_document.status).to eql 'doc_expired'
        end
      end
    end
  end
end
