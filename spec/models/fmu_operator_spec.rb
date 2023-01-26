# == Schema Information
#
# Table name: fmu_operators
#
#  id          :integer          not null, primary key
#  fmu_id      :integer          not null
#  operator_id :integer          not null
#  current     :boolean          not null
#  start_date  :date
#  end_date    :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#

require 'rails_helper'

RSpec.describe FmuOperator, type: :model do
  it 'is valid with valid attributes' do
    fmu_operator = build(:fmu_operator)
    expect(fmu_operator).to be_valid
  end

  describe 'Validations' do
    # We have a before_validation which sets start_date, so we cant test this
    #it { is_expected.to validate_presence_of(:start_date) }

    describe '#start_date_is_earlier' do
      context 'when end_date is present' do
        context 'when start_date is greater or equal to the end_date' do
          it 'add an error on start_date' do
            fmu_operator = build(:fmu_operator,
              start_date: Date.today,
              end_date: Date.yesterday)

            expect(fmu_operator.valid?).to eql false
            expect(fmu_operator.errors[:start_date]).to eql(
              ['Start date must be earlier than end date']
            )
          end
        end
      end
    end

    describe '#one_active_per_fmu' do
      context 'when fmu is present' do
        context 'when fmu has another operator active' do
          it 'add an error on current' do
            fmu_operator = create(:fmu_operator, current: true)
            fmu = fmu_operator.fmu
            another_fmu_operator = build(:fmu_operator, fmu: fmu, current: true)

            expect(another_fmu_operator.valid?).to eql false
            expect(another_fmu_operator.errors[:current]).to eql(
              ['There can only be one active operator at a time']
            )
          end
        end
      end
    end

    describe '#non_colliding_dates' do
      context 'when two operators dont have end_date' do
        it 'add an error on end_date' do
          fmu = create(:fmu)
          create(:fmu_operator, fmu: fmu, end_date: nil)
          fmu_operator = build(:fmu_operator, fmu: fmu, end_date: nil)

          expect(fmu_operator.valid?).to eql false
          expect(fmu_operator.errors[:end_date]).to eql(
            ['Cannot have two operators without end date']
          )
        end
      end

      context 'when two range dates intersect' do
        it 'add an error on start_date' do
          fmu = create(:fmu)
          create(
            :fmu_operator,
            fmu: fmu,
            start_date: Date.yesterday,
            end_date: Date.tomorrow)

          fmu_operator = build(
            :fmu_operator,
            fmu: fmu,
            start_date: Date.today,
            end_date: Date.tomorrow)

          expect(fmu_operator.valid?).to eql false
          expect(fmu_operator.errors[:start_date]).to eql(
            ['Colliding dates']
          )
        end
      end
    end
  end

  describe 'Hooks' do
    describe '#update_fmu_geojson' do
      context 'the fmu has no operator' do
        before do
          country = create(:country)
          @operator = create(:operator, country: country, fa_id: 'a')
          @fmu = create(:fmu_geojson, country: country, forest_type: 1)
          create(
            :fmu_operator,
            fmu: @fmu,
            operator: @operator,
            current: true,
            start_date: Date.current - 1.day,
            end_date: Date.current + 2.days
          )
        end
        it 'adds the operator to the geojson' do
          @fmu.geojson['properties']['company_na'] = @operator.name
        end
      end
      context 'the fmu already has an operator before updating' do
        before do
          time_a = Time.local(2020, 10, 5, 0, 0, 0)
          time_b = Time.local(2020, 10, 20, 0, 0, 0)

          country = create(:country)
          operator_a = create(:operator, country: country, fa_id: 'a')
          @operator_b = create(:operator, country: country, fa_id: 'b')
          @fmu = create(:fmu_geojson, country: country, forest_type: 1)
          travel_to time_a
          fmu_operator = create(
            :fmu_operator,
            fmu: @fmu,
            operator: operator_a,
            current: true,
            start_date: Date.current - 1.day,
            end_date: Date.current + 2.days
          )
          travel_to time_b

          fmu_operator.update(current: false)
          @fmu.reload
          create(
            :fmu_operator,
            fmu: @fmu,
            operator: @operator_b,
            current: true,
            start_date: Date.current - 1.day
          )
        end
        it 'changes the operator in the geojson' do
          @fmu.geojson['properties']['company_na'] = @operator_b.name
        end

        after do
          travel_back
        end
      end
    end
    describe '#update_documents_list' do
      context 'the operator has fa_id' do
        before do
          country = create(:country)
          @fmu = create(:fmu, country: country, forest_type: 1)

          operator = create(:operator, country: country, fa_id: 'fa_id')
          create(:fmu_operator, operator: operator, fmu: @fmu)

          another_operator = create(:operator, country: country, fa_id: 'fa_id')
          @fmu_operator =
            create(
              :fmu_operator,
              operator: another_operator,
              fmu: @fmu,
              current: false,
              start_date: Date.yesterday - 1.day,
              end_date: Date.yesterday)

          required_operator_document =
            create(:required_operator_document_fmu, country: country, forest_types: [1])

          create(
            :operator_document_fmu,
            operator: another_operator,
            fmu: @fmu,
            required_operator_document: required_operator_document)

          create_list(:required_operator_document_fmu, 3, country: country, forest_types: [1])

          @fmu.reload
        end

        it 'update the list of documents attached on itself' do
          # I think initally this test was testing callback in this model
          # but it is not needed as there are another callbacks when creating required document fmu object
          # just in case I'm leaving this comment
          # @fmu_operator.save!

          # TODO: Check if this makes sense
          # expect(
          #   OperatorDocumentFmu.where(fmu_id: @fmu.id).where.not(operator_id: @fmu.operator.id).size
          # ).to eql 0

          operator_document_fmus =
            OperatorDocumentFmu.where(fmu_id: @fmu.id, operator_id: @fmu.operator.id)
          expect(operator_document_fmus.size).to eql 4
          operator_document_fmus.each do |operator_document_fmu|
            expect(operator_document_fmu.status).to eql 'doc_not_provided'
          end
        end
      end
    end
  end

  describe 'Instance methods' do
    describe '#set_current_start_date' do
      context 'when start_date is blank' do
        it 'set start_date with the current date' do
          fmu_operator = create(:fmu_operator, start_date: nil)
          fmu_operator.set_current_start_date

          expect(fmu_operator.start_date).to eql Date.today
        end
      end
    end
  end

  describe 'Class methods' do
    describe '#calculate_current' do
      before do
        fmu = create(:fmu_geojson)
        @deactivate_fmu_operator = create(
          :fmu_operator,
          current: true,
          fmu: fmu,
          start_date: Date.yesterday - 1.day,
          end_date: Date.yesterday)

        another_fmu = create(:fmu_geojson)
        @activate_fmu_operator = create(
          :fmu_operator,
          current: false,
          fmu: another_fmu,
          start_date: Date.today,
          end_date: Date.tomorrow)
      end

      it 'deactivate old fmu_operators and activate current ones with new properties' do
        FmuOperator.calculate_current

        @deactivate_fmu_operator.reload
        expect(@deactivate_fmu_operator.current).to eql false

        @activate_fmu_operator.reload
        expect(@activate_fmu_operator.current).to eql true
        expect(@activate_fmu_operator.fmu.geojson['properties']['company_na']).to eql(
          @activate_fmu_operator.operator.name,
        )
        expect(@activate_fmu_operator.fmu.geojson['properties']['operator_id']).to eql(
           @activate_fmu_operator.operator_id
        )
      end
    end
  end
end
