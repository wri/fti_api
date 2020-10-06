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
#  is_active             :boolean          default("true")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  lat                   :decimal(, )
#  lng                   :decimal(, )
#  fmu_id                :integer
#  subcategory_id        :integer
#  validation_status     :integer          default("0"), not null
#  observation_report_id :integer
#  actions_taken         :text
#  modified_user_id      :integer
#  law_id                :integer
#  location_information  :string
#  is_physical_place     :boolean          default("true")
#  evidence_type         :integer
#  location_accuracy     :integer
#  evidence_on_report    :string
#  hidden                :boolean          default("false")
#  admin_comment         :text
#  monitor_comment       :text
#  responsible_admin_id  :integer
#  details               :text
#  concern_opinion       :text
#  litigation_status     :string
#

require 'rails_helper'

RSpec.describe Observation, type: :model do
  subject(:observation) { FactoryBot.create(:observation) }

  it 'is valid with valid attributes' do
    expect(observation).to be_valid
  end

  it 'fails if there is evidence on the report but not listed where' do
    observation = build(:observation, evidence_type: 'Evidence presented in the report')
    observation.valid?
    expect(observation.errors[:evidence_on_report]).to include('You must add information on where to find the evidence on the report')
  end

  it 'Removes old evidences when the evidence is on the report' do
    FactoryBot.create(:observation_document, observation: subject)
    expect(subject.observation_documents.count).to eql(1)
    subject.evidence_type = 'Evidence presented in the report'
    subject.evidence_on_report = '10'
    subject.save
    expect(subject.observation_documents.count).to eql(0)
  end

  # #set_active_status breaks the test on activate method
  #it_should_behave_like 'activable', :observation, FactoryBot.build(:observation)

  it_should_behave_like 'translatable',
    FactoryBot.create(:observation),
    %i[details concern_opinion litigation_status]


  describe 'Validations' do
    describe 'Status changes' do
      describe 'For a monitor' do
        let(:country) { FactoryBot.create(:country)}
        let(:observation) { FactoryBot.build(:observation, validation_status: 'Created',
                                             user_type: :monitor, country: country)}
        it 'Can create an observation'do
          observation.save
          expect(observation.persisted?).to be_truthy
        end

        it 'Can move from Created to Ready for QC' do
          observation.save
          observation.validation_status = 'Ready for QC'
          expect(observation.save).to be_truthy
        end

        it 'Cannot go to QC in progress' do
          observation.save
          observation.validation_status = 'QC in progress'
          expect(observation.save).to be_falsey
        end
      end
    end

    describe '#active_government' do
      let(:country) { create(:country) }

      context 'when type is government and government is not specified' do
        it 'add error on government' do
          observation = build(:observation_2, country: country, observation_type: 'government')
          observation.governments.update(is_active: false)
          observation.save

          expect(observation.valid?).to eql false
          expect(observation.errors[:governments]).to eql(
            ['At least one government should be active']
          )
        end
      end
    end
  end

  describe 'Hooks' do
    before :all do
      @country = create(:country)
      @operator = create(:operator, country: @country, fa_id: 'fa-id')
    end

    describe '#set_active_status' do
      context 'when validation_status is Approved' do
        it 'set is_active to true' do
          observation = create(:observation, validation_status: 'Published (no comments)')

          expect(observation.is_active).to eql true
        end
      end

      context 'when validation_status is not Approved' do
        it 'set is_active to false' do
          observation = create(:observation, validation_status: 'Needs revision')

          expect(observation.is_active).to eql false
        end
      end
    end

    describe '#check_is_physical_place' do
      context 'when there is not physical place' do
        it 'set lat, lng and fmu to nil' do
          observation = create(:observation, is_physical_place: false)

          expect(observation.lat).to eql nil
          expect(observation.lng).to eql nil
          expect(observation.fmu).to eql nil
        end
      end
    end

    describe '#set_centroid' do
      context 'when there is fmu but lat and lng are not present' do
        it 'set lat and lng with the information of the fmu properties' do
          fmu =
            create(:fmu_geojson)
          observation = create(:observation, fmu: fmu, lat: nil, lng: nil)

          expect(observation.lat).to eql(16.8545606240722)
          expect(observation.lng).to eql(-3.33605202951116)
        end
      end
    end

    describe '#update_operator_scores' do
      before do
        (0..3).each do |level|
          severity = create(:severity, level: level)
          FactoryBot.create(
            :observation,
            severity: severity,
            operator: @operator,
            country: @country,
            validation_status: 'Published (no comments)'
          )
          @operator.reload
        end
      end

      it 'calculate observation scores' do
        severity = Severity.find_by(level: 2)
        observation = create(
          :observation,
          operator: @operator,
          severity: severity,
          country: @country,
          validation_status: 'Published (no comments)')

        @operator.reload
        expect(@operator.score_operator_observation.obs_per_visit).to eql(5.0)
        expect(@operator.score_operator_observation.score).to eql((4.0 + 4.0 + 2 + 1) / 9.0)

        observation.destroy

        @operator.reload
        expect(@operator.score_operator_observation.obs_per_visit).to eql(4.0)
        expect(@operator.score_operator_observation.score).to eql((4.0 + 2.0 + 2 + 1) / 9.0)
      end
    end

    describe '#destroy_documents' do
      before do
        @observation = create(:observation, country: @country, operator: @operator)
        create_list(:observation_document, 3, observation: @observation)
      end

      it 'destroy related observation documents' do
        expect(@observation.observation_documents.size).to eql 3

        @observation.destroy

        expect(ObservationDocument.where(observation_id: @observation.id).size).to eql 0
      end
    end

    describe '#update_report_observers' do
      context 'when there is observation report' do
        it 'update the observer_ids with the observer_id associated to the observations' do
          observation_report = create(:observation_report)
          observation = create(:observation)

          observation.update_attributes(observation_report_id: observation_report.id)

          # To avoid unscope joins
          expect(observation_report.observer_ids.uniq).to eql(
            observation_report.observations.map(&:observers).map(&:ids).flatten.uniq
          )
        end
      end
    end
  end

  describe 'Instance methods' do
    describe '#user_name' do
      context 'when there is an user' do
        it 'return username' do
          user = create(:user)
          observation = create(:observation, user: user)

          expect(observation.user_name).to eql observation.user.name
        end
      end

      context 'when there is not an user' do
        it 'return nil' do
          observation = create(:observation)
          observation.update_attributes(user_id: nil)

          expect(observation.user_name).to eql nil
        end
      end
    end

    describe '#translated_type' do
      it 'return the translation of the observation type' do
        observation = create(:observation, observation_type: 'operator')

        expect(observation.translated_type).to eql I18n.t("observation_types.operator")
      end
    end

    describe '#cache_key' do
      it 'return the default value with the locale' do
        observation = create(:observation)

        expect(observation.cache_key).to match(/-#{Globalize.locale.to_s}\z/)
      end
    end
  end

  describe 'Class methods' do
    describe '#translated_types' do
      it 'return all the translations of the types' do
        translations =
          Observation.observation_types.map { |t| [I18n.t("observation_types.#{t.first}", default: t.first), t.first.camelize] }

        expect(Observation.translated_types).to eql translations
      end
    end
  end
end
