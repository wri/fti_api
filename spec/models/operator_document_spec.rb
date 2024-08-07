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
#  public                        :boolean          default(TRUE), not null
#  source                        :integer          default("company")
#  source_info                   :string
#  document_file_id              :integer
#  admin_comment                 :text
#

require "rails_helper"

RSpec.describe OperatorDocument, type: :model do
  subject(:operator_document) { FactoryBot.build(:operator_document_country) }

  it "is valid with valid attributes" do
    expect(operator_document).to be_valid
  end

  describe "Validations" do
    it "is invalid without admin comment if status is doc invalid" do
      subject.save!
      subject.status = "doc_invalid"
      expect(subject.valid?).to eq(false)
      expect(subject.errors[:admin_comment]).to include("can't be blank")
    end

    describe "#start_date" do
      context "has an attachment" do
        before { allow(subject).to receive(:document_file_id?).and_return(true) }
        it { is_expected.to validate_presence_of(:start_date) }
      end

      context "has not an attachment" do
        before { allow(subject).to receive(:document_file_id?).and_return(false) }
        it { is_expected.not_to validate_presence_of(:start_date) }
      end
    end

    describe "#set_expire_date" do
      context "when there is not expire_date" do
        it "set expire_date with the start_date plus the valid_period days" do
          operator_document = build(:operator_document_country, expire_date: nil)
          operator_document.valid?

          expect(operator_document.expire_date).to eql(
            operator_document.start_date +
              operator_document.required_operator_document.valid_period.days
          )
        end
      end
    end

    describe "#reason_or_attachment" do
      context "when there is attachment and reason" do
        it "adds an error on base" do
          operator_document = build(:operator_document_country, reason: "aaa")
          expect(operator_document.valid?).to eql false
          expect(operator_document.errors[:base]).to eql(
            ["Could either have uploaded file or reason of document non applicability"]
          )
        end
      end

      context "when there is no attachment or reason" do
        context "when status is doc_not_provided" do
          it "is valid" do
            operator_document = create(:operator_document_country, reason: nil, document_file: nil, force_status: "doc_not_provided")
            expect(operator_document.valid?).to eql true
          end
        end

        context "when status is not doc_not_provided" do
          it "adds an error on base" do
            operator_document = create(:operator_document_country, reason: nil, document_file: nil, force_status: "doc_pending")
            expect(operator_document.valid?).to eql false
            expect(operator_document.errors[:base]).to eql(
              ["File must be present or reason when document is non applicable"]
            )
          end
        end
      end
    end
  end

  describe "Hooks" do
    before do
      @country = create(:country)
      @operator = create(:operator, country: @country, fa_id: "fa_id")

      @fmu = create(:fmu, country: @country)
      @fmu_operator = create(:fmu_operator, fmu: @fmu, operator: @operator)
    end

    before do
      @required_operator_document = create(
        :required_operator_document_country,
        country: @country,
        disable_document_creation: true
      )
    end

    describe "notifications" do
      let(:operator_user) { create(:operator_user, operator: @operator) }
      let(:document) { create(:operator_document_fmu, fmu: @fmu, operator: @operator) }

      context "when changing document status to pending" do
        let(:document) { create(:operator_document_fmu, document_file: nil, reason: nil, fmu: @fmu, operator: @operator) }
        let!(:responsible_admin) { create(:admin, responsible_for_countries: [@country]) }

        subject { document.update!(status: "doc_pending", reason: "it's not required") }

        it "sends an email to all reponsible admins for this operator" do
          expect { subject }.to have_enqueued_mail(OperatorDocumentMailer, :admin_document_pending).exactly(1).times
            .and have_enqueued_mail(OperatorDocumentMailer, :admin_document_pending).with(document, responsible_admin)
        end
      end

      context "when validating document" do
        subject { document.update!(status: "doc_valid") }

        it "sends an email to observer users" do
          expect { subject }.to have_enqueued_mail(OperatorDocumentMailer, :document_valid).exactly(1).times
            .and have_enqueued_mail(OperatorDocumentMailer, :document_valid).with(document, operator_user)
        end
      end

      context "when rejecting document" do
        subject { document.update!(status: "doc_invalid", admin_comment: "wrong file") }

        it "sends an email to observer users" do
          expect { subject }.to have_enqueued_mail(OperatorDocumentMailer, :document_invalid).exactly(1).times
            .and have_enqueued_mail(OperatorDocumentMailer, :document_invalid).with(document, operator_user)
        end
      end

      context "when accepting document as not required" do
        let(:document) { create(:operator_document_fmu, reason: "Not required document", document_file: nil, fmu: @fmu, operator: @operator) }

        subject { document.update!(status: "doc_not_required") }

        it "sends an email to observer users" do
          expect { subject }.to have_enqueued_mail(OperatorDocumentMailer, :document_accepted_as_not_required).exactly(1).times
            .and have_enqueued_mail(OperatorDocumentMailer, :document_accepted_as_not_required).with(document, operator_user)
        end
      end
    end

    describe "#set_status" do
      context "when attachment or reason are not present" do
        it "update status as doc_not_provided" do
          operator_document = create(:operator_document_country, reason: nil, document_file: nil)

          expect(operator_document.status).to eql "doc_not_provided"
        end
      end
    end

    describe "#remove_notifications" do
      let(:notification_days) { 10 }
      let(:notification_group) { create :notification_group, days: notification_days }
      let!(:notification) {
        create :notification, operator_document: operator_document, notification_group: notification_group
      }
      let!(:notification2) { create :notification, operator_document: operator_document, solved_at: Date.yesterday }
      subject { operator_document.save! }

      context "when not updating the expire date" do
        before do
          operator_document.note = "test"
        end
        it "does not remove the notification" do
          expect { subject }.not_to change { notification.reload.solved_at }
        end
      end

      context "when updating the expire date" do
        before do
          operator_document.expire_date = Time.zone.today + 1.month
        end

        context "when the expire date is bigger than the notification date" do
          let(:notification_days) { 1 }

          it "sets the `solved at` for the notification" do
            expect { subject }.to change { notification.reload.solved_at }
          end

          it "does not updated `solved at` for notifications that were already solved" do
            expect { subject }.not_to change { notification2.reload.solved_at }
          end
        end

        context "when the expire date is smaller than the notification date" do
          let(:notification_days) { 365 }

          it "does not update the notifications" do
            expect { subject }.not_to change { notification.reload.solved_at }
            expect { subject }.not_to change { notification2.reload.solved_at }
          end
        end
      end
    end

    describe "#recalculate operator score" do
      before { @document = create(:operator_document_fmu, fmu: @fmu, operator: @operator) }
      before { expect(ScoreOperatorDocument).to receive(:recalculate!).with(@operator) }

      context "when removing document" do
        it "updates operator score" do
          @document.destroy
        end

        context "while fmu does not belong to operator anymore" do
          it "updates operator score" do
            @fmu_operator.update(current: false) # this should invoke document deletion and invoke recalculation
            expect(@document.reload.deleted?).to be(true)
          end
        end
      end

      context "when changing document status" do
        it "updates operator score" do
          @document.update!(status: :doc_valid)
        end
      end

      context "when operator not approved and changing public state" do
        before { @operator.update(approved: false) }

        it "updates operator score" do
          @document.update!(public: @document.public)
        end
      end
    end

    describe "#update_operator_percentages" do
      before do
        valid_status = OperatorDocument.statuses[:doc_valid]
        pending_status = OperatorDocument.statuses[:doc_pending]
        common_data = {
          operator_id: @operator.id,
          required_operator_document_id: @required_operator_document.id,
          public: true
        }

        # Generate one valid operator document and two pending operator documents of each type
        valid_op_doc = create(:operator_document_country, **common_data)
        valid_op_doc.reload
        valid_op_doc.update(status: valid_status)
        @operator.reload

        pending_op_docs = create_list(:operator_document_country, 2, **common_data)
        pending_op_docs.each do |pending_op_doc|
          pending_op_doc.update(status: pending_status)
          @operator.reload
        end
      end

      it "update valid operator percentages" do
        @operator.reload
        expect(@operator.score_operator_document.all.round(2)).to eql (1.0 / 3.0).round(2)

        operator_document = OperatorDocument.where(
          operator_id: @operator.id,
          required_operator_document_id: @required_operator_document.id,
          status: OperatorDocument.statuses[:doc_valid]
        ).first

        expect {
          operator_document.update(status: OperatorDocument.statuses[:doc_not_required])
        }.to change { OperatorDocumentHistory.count }.by(1)

        @operator.reload
        expect(@operator.score_operator_document.all).to eql 0.0
      end
    end

    describe "#destroy" do
      it "regenerates document state to not provided and creates history for current document" do
        operator_document = create(
          :operator_document_country,
          operator: @operator,
          status: :doc_valid,
          required_operator_document: @required_operator_document
        )

        expect(OperatorDocument.count).to eql 1

        expect {
          operator_document.destroy
        }.to change { OperatorDocumentHistory.count }.by(1)

        operator_document.reload

        expect(OperatorDocument.count).to eql 1
        expect(operator_document.deleted?).to be(false)
        expect(operator_document.status).to eq("doc_not_provided")
      end
    end
  end

  describe "Instance methods" do
    describe "#expire_document" do
      let!(:operator_document) { create(:operator_document_country, force_status: status) }

      context "when document status is valid" do
        let(:status) { :doc_valid }

        it "update status as doc_expired" do
          expect {
            operator_document.expire_document
          }.to change { OperatorDocumentHistory.count }.by(1)

          expect(operator_document.status).to eql "doc_expired"
        end
      end

      context "when document status is not required" do
        let(:status) { :doc_not_required }

        it "update status as doc_not_provided" do
          expect {
            operator_document.expire_document
          }.to change { OperatorDocumentHistory.count }.by(1)

          expect(operator_document.status).to eql "doc_not_provided"
        end
      end

      context "with other statuses" do
        let(:status) { :doc_pending }

        it "does not do anything" do
          expect {
            operator_document.expire_document
          }.not_to change { OperatorDocumentHistory.count }

          expect(operator_document.status).to eql "doc_pending"
        end
      end
    end
  end

  describe "Class methods" do
    describe "#expire_documents" do
      let!(:rod) { create(:required_operator_document_country, contract_signature: false) }
      let!(:od) {
        create(
          :operator_document_country,
          required_operator_document: rod,
          force_status: status,
          expire_date: expire_date
        )
      }

      subject { OperatorDocument.expire_documents }

      context "when the date is in the past" do
        let(:expire_date) { Time.zone.today - 1.year }

        context "when the status is valid" do
          let(:status) { :doc_valid }

          it { expect { subject }.to change { od.reload.status }.from("doc_valid").to("doc_expired") }
        end

        context "when the status is not required" do
          let(:status) { :doc_not_required }

          it { expect { subject }.to change { od.reload.status }.from("doc_not_required").to("doc_not_provided") }
        end

        context "when the status is pending" do
          let(:status) { :doc_pending }

          it { expect { subject }.to_not change { od.reload.status } }
        end
      end

      context "when the date is in the future" do
        let(:expire_date) { Time.zone.today + 1.year }
        let(:status) { :doc_valid }

        it { expect { subject }.to_not change { od.reload.status } }
      end
    end
  end
end
