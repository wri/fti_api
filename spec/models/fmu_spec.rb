require 'rails_helper'

RSpec.describe Fmu, type: :model do
  it 'is valid with valid attributes' do
    fmu = FactoryBot.build :fmu
    expect(fmu).to be_valid
  end

  it_should_behave_like 'translatable', FactoryBot.create(:fmu), %i[name]

  describe 'Relations' do
    it { is_expected.to belong_to(:country).inverse_of(:fmus) }
    it { is_expected.to have_many(:observations).inverse_of(:fmu) }
    it { is_expected.to have_many(:fmu_operators).inverse_of(:fmu).dependent(:destroy) }
    it { is_expected.to have_many(:operators).through(:fmu_operators) }
    it { is_expected.to have_many(:operator_document_fmus).dependent(:destroy) }
  end

  it { is_expected.to accept_nested_attributes_for(:operators) }

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:country_id) }
    it { is_expected.to validate_presence_of(:forest_type) }
  end

  describe 'Methods' do
    context '#cache_key' do
      it 'return the default value with the locale' do
        fmu = FactoryBot.build :fmu
        expect(fmu.cache_key).to match(/-#{Globalize.locale.to_s}\z/)
      end
    end
  end

  describe 'Hooks' do
    context '#update_geojson' do
      context 'when geojson is blank' do
        it 'return nil' do
          fmu = FactoryBot.create :fmu, geojson: nil
          expect(fmu.geojson).to eql nil
        end
      end

      context 'when geojson is present' do
        it 'fill geojson with properties from fmu' do
          country = FactoryBot.create :country
          operator = FactoryBot.create :operator, country: country, fa_id: 'fa_id'
          fmu = FactoryBot.create :fmu, geojson: {properties: {}}, country: country
          FactoryBot.create(:fmu_operator, fmu: fmu, operator: operator)
          fmu.reload
          fmu.save

          expect(fmu.geojson['properties']['fmu_name']).to eql fmu.name
          expect(fmu.geojson['properties']['company_na']).to eql fmu.operator.name
          expect(fmu.geojson['properties']['operator_id']).to eql fmu.operator.id
          expect(fmu.geojson['properties']['certification_fsc']).to eql fmu.certification_fsc
          expect(fmu.geojson['properties']['certification_pefc']).to eql fmu.certification_pefc
          expect(fmu.geojson['properties']['certification_olb']).to eql fmu.certification_olb
          expect(fmu.geojson['properties']['certification_vlc']).to eql fmu.certification_vlc
          expect(fmu.geojson['properties']['certification_vlo']).to eql fmu.certification_vlo
          expect(fmu.geojson['properties']['certification_tltv']).to eql fmu.certification_tltv
        end
      end
    end

    context '#really_destroy_documents' do
      it 'destroy operator_documents associated with the fmu' do
        another_fmu = FactoryBot.create(:fmu)
        operator_document = FactoryBot.create(:operator_document, fmu: another_fmu)
        another_fmu.destroy

        expect(OperatorDocument.where(id: operator_document.id).first).to be_nil
      end
    end
  end

  describe 'Instance methods' do
    context '#cache_key' do
      it 'return the default value with the locale' do
        fmu = FactoryBot.create :fmu
        expect(fmu.cache_key).to match(/-#{Globalize.locale.to_s}\z/)
      end
    end
  end

  describe 'Class methods' do
    before :all do
      @country = FactoryBot.create :country
      operator = FactoryBot.create :operator, fa_id: 'fa-id'
      @operator = FactoryBot.create :operator, country: @country, fa_id: 'fa_id'

      FactoryBot.create(:fmu, country: @country)
      fmu1 = FactoryBot.create(:fmu, country: operator.country)
      fmu2 = FactoryBot.create(:fmu, country: @country)

      FactoryBot.create(:fmu_operator, fmu: fmu1, operator: operator)
      FactoryBot.create(:fmu_operator, fmu: fmu2, operator: @operator)
    end

    context 'when country_ids and operator_ids are not specified' do
      it 'fetch all fmu' do
        expect(Fmu.fetch_all(nil).count).to eq(Fmu.all.size)
      end
    end

    context 'when country_ids is specified' do
      it 'fetch fmus filtered by country' do
        expect(Fmu.fetch_all({'country_ids' => @country.id.to_s}).to_a).to eql(
          Fmu.where(country_id: @country.id).to_a
        )
      end
    end

    context 'when operator_ids is specified' do
      it 'fetch fmus filtered by operator' do
        expect(Fmu.fetch_all({'operator_ids' => @operator.id.to_s}).to_a).to eql(
          Fmu.joins(:fmu_operators).where(fmu_operators: {current: true, operator_id: @operator.id}).to_a
        )
      end
    end

    context 'when free is specified' do
      it 'fetch fmus filtered by free' do
        expect(Fmu.fetch_all({'free' => 'true'}).to_a).to eql(
          Fmu.where.not(id: FmuOperator.where(current: :true).pluck(:fmu_id)).group(:id).to_a
        )
      end
    end
  end
end
