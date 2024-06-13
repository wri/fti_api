# == Schema Information
#
# Table name: observations
#
#  id                    :integer          not null, primary key
#  severity_id           :integer
#  observation_type      :integer          not null
#  user_id               :integer
#  publication_date      :datetime
#  country_id            :integer
#  operator_id           :integer
#  pv                    :string
#  is_active             :boolean          default(TRUE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  lat                   :decimal(, )
#  lng                   :decimal(, )
#  fmu_id                :integer
#  subcategory_id        :integer
#  validation_status     :integer          default("Created"), not null
#  observation_report_id :integer
#  actions_taken         :text
#  modified_user_id      :integer
#  law_id                :integer
#  location_information  :string
#  is_physical_place     :boolean          default(TRUE), not null
#  evidence_type         :integer
#  location_accuracy     :integer
#  evidence_on_report    :string
#  hidden                :boolean          default(FALSE), not null
#  admin_comment         :text
#  monitor_comment       :text
#  deleted_at            :datetime
#  locale                :string
#  details               :text
#  concern_opinion       :text
#  litigation_status     :string
#  deleted_at            :datetime
#

require "rails_helper"

RSpec.describe Observation, type: :model do
  subject(:observation) { build(:observation) }

  it "Removes old evidences when the evidence is on the report" do
    subject.evidence_type = "Uploaded documents"
    subject.observation_documents << create(:observation_document)
    subject.save!
    expect(subject.observation_documents.count).to eql(1)
    subject.evidence_type = "Evidence presented in the report"
    subject.evidence_on_report = "10"
    subject.save!
    expect(subject.observation_documents.count).to eql(0)
  end

  # #set_active_status breaks the test on activate method
  # it_should_behave_like 'activable', :observation, FactoryBot.build(:observation)

  it_should_behave_like "translatable",
    :observation,
    %i[details concern_opinion litigation_status]

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it { is_expected.to validate_numericality_of(:lat).is_greater_than_or_equal_to(-90).allow_nil }
    it { is_expected.to validate_numericality_of(:lat).is_less_than_or_equal_to(90).allow_nil }
    it { is_expected.to validate_numericality_of(:lng).is_greater_than_or_equal_to(-180).allow_nil }
    it { is_expected.to validate_numericality_of(:lng).is_less_than_or_equal_to(180).allow_nil }

    it "is invalid there is evidence on the report but not listed where" do
      subject.evidence_type = "Evidence presented in the report"
      expect(subject.valid?).to eq(false)
      expect(subject.errors[:evidence_on_report]).to include("can't be blank")
    end

    it "is invalid without observers" do
      subject.observers = []
      subject.observation_report = nil # clearing the report as well to not copy observers from there
      expect(subject.valid?).to eq(false)
      expect(subject.errors[:observers]).to include("can't be blank")
    end

    it "is invalid without admin comment if status is needs revision" do
      subject.validation_status = "Needs revision"
      expect(subject.valid?).to eq(false)
      expect(subject.errors[:admin_comment]).to include("can't be blank")
    end

    it "is invalid with governments if is of operator type" do
      subject.governments = build_list(:government, 1)
      subject.observation_type = :operator
      expect(subject.valid?).to eq(false)
      expect(subject.errors[:governments]).to include("Should have no governments with 'operator' type")
    end

    describe "#status_changes" do
      let(:country) { create(:country) }
      let(:status) { "Created" }
      let(:operator) { create(:operator, country: country) }
      let(:observation) {
        build :observation,
          country: country,
          operator: operator,
          validation_status: status
      }
      subject {
        observation.user_type = user_type
        observation.save
        observation
      }

      describe "For a monitor" do
        let(:user_type) { :monitor }

        context "when creating an observation with status `Created`" do
          it { is_expected.to be_valid }
          it { is_expected.to be_persisted }
        end

        context "when it is already saved" do
          before do
            observation.save!
            observation.validation_status = new_status
          end

          context "when moving from `Created` to `Ready for QA`" do
            let(:new_status) { "Ready for QC" }

            it { is_expected.to be_valid }
          end

          context "when going to QC in progress" do
            let(:new_status) { "QC in progress" }

            it { is_expected.to_not be_valid }
          end
        end
      end

      describe "for an admin" do
        let(:user_type) { :admin }

        before do
          # looks like validate: false does not work correctly from Rails 6.0,
          # and below code breaks in Rails 6.1 because of new active_record.has_many_inversing = true value
          # belongs_to country is required for observation and as inverse is working then if country is invalid
          # then observation is invalid, country is invalid because it checks if observations are valid now. I know it's confusing
          # and I got to that with trial and error
          # https://github.com/rails/rails/issues/43400
          # https://github.com/rails/rails/pull/42748
          #
          # to not have invalid object I moved
          # setting user_type to subject to not invoke status_changes validation
          observation.save # save(validate: false)
          observation.validation_status = new_status
        end

        context "when moving from `Ready for QC` to `QC in progress`" do
          let(:status) { "Ready for QC" }
          let(:new_status) { "QC in progress" }

          it { is_expected.to be_valid }
        end

        context "when moving from `Created` to `Ready for QC`" do
          let(:status) { "Created" }
          let(:new_status) { "Ready for QC" }

          it { is_expected.to_not be_valid }
        end
      end

      describe "for all" do
        context "with unknown operator" do
          let(:operator) { create(:unknown_operator) }
          before { observation.save }
          subject { observation }

          context "when creating an observation with status `Created`" do
            it { is_expected.to be_valid }
            it { is_expected.to be_persisted }
          end

          context "when moving to 'Ready for QC'" do
            it "should not be valid" do
              observation.validation_status = "Ready for QC"
              observation.operator = Operator.find_by(slug: "unknown")
              expect(observation.save).to be false
              expect(observation.errors[:operator]).to eql ["can't be blank or unknown"]
            end
          end
        end
      end
    end

    describe "#active_government" do
      let(:country) { create(:country) }

      context "when type is government and government is not specified" do
        it "add error on government" do
          observation = build(:gov_observation, country: country, observation_type: "government")
          observation.governments.update(is_active: false)
          observation.save

          expect(observation.valid?).to eql false
          expect(observation.errors[:governments]).to eql(
            ["At least one government should be active"]
          )
        end
      end
    end
  end

  describe "Hooks" do
    before :all do
      @country = create(:country)
      @operator = create(:operator, country: @country, fa_id: "fa-id")
    end

    describe "notifications" do
      let(:admin1) { create(:admin) }
      let(:admin2) { create(:admin) }
      let(:observer1) { create(:observer, responsible_admin: admin1) }
      let(:observer2) { create(:observer, responsible_admin: admin2) }
      let(:observation_report) { create(:observation_report, observers: [observer1, observer2]) }
      let(:observation) {
        build(
          :observation,
          validation_status: "Created",
          observation_report: observation_report
        )
      }

      before do
        @inactive_user = create(:user, user_role: :ngo_manager, observer: observer1, is_active: false)
        @user1 = create(:user, user_role: :ngo_manager, observer: observer1)
        @user2 = create(:user, user_role: :ngo_manager, observer: observer2)
        @user3 = create(:user, user_role: :ngo_manager, observer: observer2)
        @observers_manager = create(:user, user_role: :ngo_manager, observer: create(:observer), managed_observers: [observer1, observer2])
      end

      context "when observation is created" do
        subject { observation.save! }

        it "sends an email to observer users" do
          expect { subject }.to have_enqueued_mail(ObservationMailer, :observation_created).exactly(4).times
            .and have_enqueued_mail(ObservationMailer, :observation_created).with(observation, @user1)
            .and have_enqueued_mail(ObservationMailer, :observation_created).with(observation, @user2)
            .and have_enqueued_mail(ObservationMailer, :observation_created).with(observation, @user3)
            .and have_enqueued_mail(ObservationMailer, :observation_created).with(observation, @observers_manager)
        end
      end

      context "when was created before" do
        before { observation.save! }

        context "when validation status is changed to `Ready for QC`" do
          subject { observation.update!(validation_status: "Ready for QC") }

          it "sends an email to observer users" do
            expect { subject }.to have_enqueued_mail(ObservationMailer, :observation_submitted_for_qc).exactly(3).times
          end

          it "sends an email to all observers responsible admins" do
            expect { subject }.to have_enqueued_mail(ObservationMailer, :admin_observation_ready_for_qc).with(observation, admin1)
              .and have_enqueued_mail(ObservationMailer, :admin_observation_ready_for_qc).with(observation, admin2)
          end

          it "does not send email to inactive users" do
            expect { subject }.to have_not_enqueued_mail(ObservationMailer, :observation_submitted_to_qc).with(observation, @inactive_user)
          end
        end

        context "when validation status is changed to `Needs revision`" do
          subject { observation.update!(validation_status: "Needs revision", admin_comment: "Some comment") }

          it "sends an email to observer users" do
            expect { subject }.to have_enqueued_mail(ObservationMailer, :observation_needs_revision).exactly(3).times
          end
        end

        context "when validation status is changed to `Ready for publication`" do
          subject { observation.update!(validation_status: "Ready for publication") }

          it "sends an email to observer users" do
            expect { subject }.to have_enqueued_mail(ObservationMailer, :observation_ready_for_publication).exactly(3).times
          end
        end

        context "when validation status is changed to `Published (not modified)`" do
          subject { observation.update!(validation_status: "Published (not modified)") }

          it "sends an email to observer users" do
            expect { subject }.to have_enqueued_mail(ObservationMailer, :observation_published).exactly(3).times
          end

          it "sends an email to all observers responsible admins" do
            expect { subject }.to have_enqueued_mail(ObservationMailer, :admin_observation_published_not_modified).with(observation, admin1)
              .and have_enqueued_mail(ObservationMailer, :admin_observation_published_not_modified).with(observation, admin2)
          end
        end
      end
    end

    describe "#assign_observers_from_report" do
      let(:observer1) { create(:observer) }
      let(:observer2) { create(:observer) }
      let(:observation_report) { create(:observation_report, observers: [observer1, observer2]) }
      let(:observation) { create(:observation, observation_report: observation_report) }

      context "when creating an observation" do
        it "assigns the observers from the report" do
          expect(observation.observers).to match_array([observer1, observer2])
        end
      end

      context "when changing observation report" do
        let(:observer3) { create(:observer) }
        let(:observation_report2) { create(:observation_report, observers: [observer3]) }

        it "assigns the observers from the report" do
          observation.update!(observation_report: observation_report2)
          expect(observation.observers).to match_array([observer3])
        end
      end
    end

    describe "#set_publication_date" do
      context "when publishing an observation" do
        it "set publication_date with the current date" do
          observation = create(:observation, validation_status: "Created")
          expect(observation.publication_date).to eql nil
          observation.update!(validation_status: "Published (no comments)")
          expect(observation.publication_date.to_date).to eql Date.current
        end
      end
    end

    describe "#set_active_status" do
      context "when validation_status is Approved" do
        it "set is_active to true" do
          observation = create(:observation, validation_status: "Published (no comments)")

          expect(observation.is_active).to eql true
        end
      end

      context "when validation_status is not Approved" do
        it "set is_active to false" do
          observation = create(:observation, validation_status: "Needs revision", admin_comment: "Comment")

          expect(observation.is_active).to eql false
        end
      end
    end

    describe "#nullify_fmu_and_coordinates" do
      context "when there is not physical place" do
        it "set lat, lng and fmu to nil" do
          observation = create(:observation, is_physical_place: false)

          expect(observation.lat).to eql nil
          expect(observation.lng).to eql nil
          expect(observation.fmu).to eql nil
        end
      end
    end

    describe "#set_centroid" do
      context "when there is fmu but lat and lng are not present" do
        it "set lat and lng with the information of the fmu properties" do
          fmu =
            create(:fmu_geojson)
          observation = create(:observation, fmu: fmu, lat: nil, lng: nil)

          expect(observation.lng).to eql(16.8545606240722)
          expect(observation.lat).to eql(-3.33605202951116)
        end
      end
    end

    describe "#update_operator_scores" do
      before do
        4.times do |level|
          severity = create(:severity, level: level)
          FactoryBot.create(
            :observation,
            severity: severity,
            operator: @operator,
            country: @country,
            validation_status: "Published (no comments)"
          )
          @operator.reload
        end
      end

      it "calculate observation scores" do
        severity = Severity.find_by(level: 2)
        observation = create(
          :observation,
          operator: @operator,
          severity: severity,
          country: @country,
          validation_status: "Published (no comments)"
        )

        @operator.reload
        expect(@operator.score_operator_observation.obs_per_visit).to eql(5.0)
        expect(@operator.score_operator_observation.score).to eql((4.0 + 4.0 + 2 + 1) / 9.0)

        observation.destroy

        @operator.reload
        expect(@operator.score_operator_observation.obs_per_visit).to eql(4.0)
        expect(@operator.score_operator_observation.score).to eql((4.0 + 2.0 + 2 + 1) / 9.0)
      end
    end

    describe "#destroy_documents" do
      before do
        @observation = create(:observation, country: @country, operator: @operator)
        @observation.observation_documents = create_list(:observation_document, 3)
      end

      it "destroy related observation documents" do
        expect(@observation.observation_documents.size).to eql 3

        @observation.destroy

        expect(ObservationDocument.joins(:observations).where(observations: [@observation]).size).to eql 0
      end
    end

    describe "#force_translations" do
      let(:observation) { create(:observation, :with_translations, validation_status: "Ready for publication") }

      context "when changing the status to something other than published" do
        it "does not call the translation job" do
          expect(TranslationJob).to_not receive(:perform_later)
          observation.update(validation_status: "Needs revision")
        end
      end

      context "when changing the status to published" do
        context "when the language is not supported" do
          it "does not call the translation job" do
            expect(TranslationJob).to_not receive(:perform_later)
            observation.force_translations_from = :es
            observation.update(validation_status: "Published (no comments)")
          end
        end

        it "calls the translation job" do
          expect(TranslationJob).to receive(:perform_later)
          observation.force_translations_from = :fr
          observation.update(validation_status: "Published (no comments)")
        end
      end
    end
  end

  describe "Instance methods" do
    describe "#user_name" do
      context "when there is an user" do
        it "return username" do
          user = create(:user)
          observation = create(:observation, user: user)

          expect(observation.user_name).to eql observation.user.name
        end
      end

      context "when there is not an user" do
        it "return nil" do
          observation = create(:observation)
          observation.update(user: nil)

          expect(observation.user_name).to eql nil
        end
      end
    end

    describe "#translated_type" do
      it "return the translation of the observation type" do
        observation = create(:observation, observation_type: "operator")

        expect(observation.translated_type).to eql I18n.t("observation_types.operator")
      end
    end

    describe "#cache_key" do
      it "return the default value with the locale" do
        observation = create(:observation)

        expect(observation.cache_key).to match(/-#{Globalize.locale}\z/)
      end
    end
  end

  describe "Class methods" do
    describe "#translated_types" do
      it "return all the translations of the types" do
        translations =
          Observation.observation_types.map { |t| [I18n.t("observation_types.#{t.first}", default: t.first), t.first.camelize] }

        expect(Observation.translated_types).to eql translations
      end
    end
  end
end
