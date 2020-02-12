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
#  government_id         :integer
#  pv                    :string
#  is_active             :boolean          default(TRUE)
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
#  is_physical_place     :boolean          default(TRUE)
#

require 'rails_helper'

RSpec.describe Observation, type: :model do
  subject(:observation) { FactoryBot.create(:observation) }

  it 'is valid with valid attributes' do
    expect(observation).to be_valid
  end

  # #set_active_status breaks the test on activate method
  #it_should_behave_like 'activable', :observation, FactoryBot.build(:observation)

  it_should_behave_like 'translatable',
    FactoryBot.create(:observation),
    %i[details evidence concern_opinion litigation_status]

  describe 'Enums' do
    it { is_expected.to define_enum_for(:observation_type).with_values(%w[operator government]) }
    it { is_expected.to define_enum_for(:validation_status).with_values(
      %w[Created Ready\ for\ revision Under\ revision Approved Rejected]
    ) }
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:country).inverse_of(:observations) }
    it { is_expected.to belong_to(:severity).inverse_of(:observations) }
    it { is_expected.to belong_to(:operator).inverse_of(:observations) }
    it { is_expected.to belong_to(:government).inverse_of(:observations).optional }
    it { is_expected.to belong_to(:user).inverse_of(:observations).optional }
    it { is_expected.to belong_to(:modified_user).class_name('User').with_foreign_key('modified_user_id').optional }
    it { is_expected.to belong_to(:fmu).inverse_of(:observations).optional }
    it { is_expected.to belong_to(:law).inverse_of(:observations).optional }
    it { is_expected.to belong_to(:subcategory).inverse_of(:observations).optional }
    it { is_expected.to belong_to(:observation_report) }

    it { is_expected.to have_many(:species_observations) }
    it { is_expected.to have_many(:species).through(:species_observations) }
    it { is_expected.to have_many(:observer_observations).dependent(:destroy) }
    it { is_expected.to have_many(:observers).through(:observer_observations) }
    it { is_expected.to have_many(:observation_operators).dependent(:destroy) }
    it { is_expected.to have_many(:relevant_operators).through(:observation_operators).source(:operator) }
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:photos).dependent(:destroy) }
    it { is_expected.to have_many(:observation_documents) }
  end

  describe 'Nested attributes' do
    it { is_expected.to accept_nested_attributes_for(:photos).allow_destroy(true) }
    it { is_expected.to accept_nested_attributes_for(:observation_documents).allow_destroy(true) }
    it { is_expected.to accept_nested_attributes_for(:observation_report).allow_destroy(true) }
    it { is_expected.to accept_nested_attributes_for(:subcategory).allow_destroy(false) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:country_id) }
    it { is_expected.to validate_presence_of(:publication_date) }
    it { is_expected.to validate_presence_of(:validation_status) }
    it { is_expected.to validate_presence_of(:observation_type) }

    describe '#active_government' do
      context 'when type is government and government is not specified' do
        it 'add error on government' do
          observation = build(:observation, observation_type: 'government')
          observation.government.update_attributes(is_active: false)
          observation.save

          expect(observation.valid?).to eql false
          expect(observation.errors[:government]).to eql(
            ['The selected government is not active']
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
          observation = create(:observation, validation_status: 'Approved')

          expect(observation.is_active).to eql true
        end
      end

      context 'when validation_status is not Approved' do
        it 'set is_active to false' do
          observation = create(:observation, validation_status: 'Rejected')

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
            create(:fmu, geojson: { properties: { centroid: { coordinates: [10.91, -4.32] } } })
          observation = create(:observation, fmu: fmu, lat: nil, lng: nil)

          expect(observation.lat).to eql(10.91)
          expect(observation.lng).to eql(-4.32)
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
            validation_status: 'Approved'
          )
        end
      end

      it 'calculate observation scores' do
        severity = Severity.find_by(level: 2)
        observation = create(
          :observation,
          operator: @operator,
          severity: severity,
          country: @country,
          validation_status: 'Approved')

        expect(@operator.obs_per_visit).to eql(5.0)
        expect(@operator.score_absolute).to eql((4.0 + 4.0 + 2 + 1) / 9.0)

        observation.destroy

        expect(@operator.obs_per_visit).to eql(4.0)
        expect(@operator.score_absolute).to eql((4.0 + 2.0 + 2 + 1) / 9.0)
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
