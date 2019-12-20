# == Schema Information
#
# Table name: observers
#
#  id                :integer          not null, primary key
#  observer_type     :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default(TRUE)
#  logo              :string
#  address           :string
#  information_name  :string
#  information_email :string
#  information_phone :string
#  data_name         :string
#  data_email        :string
#  data_phone        :string
#  organization_type :string
#

require 'rails_helper'

RSpec.describe Observer, type: :model do
  subject(:observer) { FactoryBot.build(:observer) }

  it 'is valid with valid attributes' do
    expect(observer).to be_valid
  end

  it_should_behave_like 'translatable', FactoryBot.create(:observer), %i[name organization]

  describe 'Relations' do
    it { is_expected.to have_and_belong_to_many(:countries) }
    it { is_expected.to have_many(:observer_observations).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:observations).through(:observer_observations) }
    it { is_expected.to have_many(:observation_report_observers).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:observation_reports).through(:observation_report_observers) }
    it { is_expected.to have_many(:users).inverse_of(:observer) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:observer_type) }

    it { is_expected.to validate_inclusion_of(:observer_type)
      .in_array(%w[Mandated SemiMandated External Government])
      .with_message(/is not a valid observer type/)
    }
    it { is_expected.to validate_inclusion_of(:organization_type)
      .in_array(['NGO', 'Academic', 'Research Institute', 'Private Company', 'Other'])
    }

    it { is_expected.to allow_value('email@email.com').for(:information_email) }
    it { is_expected.to allow_value('email@email.com').for(:data_email) }
  end

  describe 'Instance methods' do
    describe '#cache_key' do
      it 'return the default value with the locale' do
        expect(observer.cache_key).to match(/-#{Globalize.locale.to_s}\z/)
      end
    end
  end

  describe 'Class methods' do
    before do
      create_list(:observer, 3)
    end

    describe '#fetch_all' do
      it 'fetch all operators' do
        expect(Observer.fetch_all(nil)).to eq(Observer.includes(:countries, :users))
      end
    end

    describe '#observer_select' do
      it 'return formatted information of observer sorted by name asc' do
        expect(Observer.observer_select).to eql(
          Observer.by_name_asc.map { |c| ["#{c.name} (#{c.observer_type})", c.id] }
        )
      end
    end

    describe '#types' do
      it 'return types for the observers' do
        expect(Observer.types).to eql %w(Mandated SemiMandated External Government).freeze
      end
    end

    describe '#translated_types' do
      it 'return transated types for the observers' do
        translated_types =
          Observer.types.map { |t| [I18n.t("observer_types.#{t}", default: t), t.camelize] }

        expect(Observer.translated_types).to eql translated_types
      end
    end
  end
end
