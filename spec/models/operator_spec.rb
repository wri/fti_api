# == Schema Information
#
# Table name: operators
#
#  id                :integer          not null, primary key
#  operator_type     :string
#  country_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default(TRUE), not null
#  logo              :string
#  operator_id       :string
#  fa_id             :string
#  address           :string
#  website           :string
#  approved          :boolean          default(TRUE), not null
#  holding_id        :integer
#  country_doc_rank  :integer
#  country_operators :integer
#  name              :string
#  details           :string
#  slug              :string
#

require "rails_helper"

RSpec.describe Operator, type: :model do
  subject(:operator) { build(:operator) }

  before :all do
    @country = create(:country)
    @operator = create(:operator, country: @country, fa_id: "fa-id")
    @required_operator_document_group = create(:required_operator_document_group)

    fmu = create(:fmu, country: @country)
    create(:fmu_operator, fmu: fmu, operator: @operator)

    required_operator_document_data = {
      country: @country,
      required_operator_document_group: @required_operator_document_group
    }
    @signature_document = create(:required_operator_document_country, country: @country, contract_signature: true)
    @required_operator_document =
      create(:required_operator_document, **required_operator_document_data)
    @required_operator_document_country =
      create(:required_operator_document_country, **required_operator_document_data)
    @required_operator_document_fmu =
      create(:required_operator_document_fmu, **required_operator_document_data)
  end

  it "is valid with valid attributes" do
    expect(operator).to be_valid
  end

  it "is invalid with invalid website url" do
    operator.website = "invalid url"
    expect(operator).not_to be_valid
    expect(operator.errors[:website]).to include("is invalid")

    operator.website = "validurl.com"
    expect(operator).not_to be_valid
    expect(operator.errors[:website]).to include("must start with http:// or https://")
  end

  describe "Hooks" do
    describe "#set_slug" do
      it "sets slug for a new operator" do
        operator.name = "New Operator"
        operator.save!
        expect(operator.slug).to eql "new-operator"
      end

      it "sets slug after changing name" do
        operator.save!
        operator.name = "New Operator Name"
        operator.save!
        expect(operator.slug).to eql "new-operator-name"
      end
    end

    describe "#create_operator_id" do
      context "when country is present" do
        it "update operator_id using the country and id" do
          expect(@operator.operator_id).to eql "#{@country.iso}-unknown-#{@operator.id}"
        end
      end

      context "when country is not present" do
        it "update the id" do
          operator = create(:operator)
          expect(operator.operator_id).to eql "#{operator.country.iso}-unknown-#{operator.id}"
        end
      end
    end

    describe "#create_documents" do
      context "when setting fa_id for operator" do
        before do
          # Having a random order, @operator data can differ depending on the order
          other_country = create(:country)
          @other_operator = create(:operator, country: other_country, fa_id: nil)

          fmu = create(:fmu, forest_type: "ufa", country: other_country)
          FactoryBot.create(:fmu_operator, fmu: fmu, operator: @other_operator)

          required_operator_document_data = {
            country: other_country,
            required_operator_document_group: @required_operator_document_group
          }
          FactoryBot.create(:required_operator_document_country, **required_operator_document_data)
          FactoryBot.create(
            :required_operator_document_fmu,
            forest_types: [ForestType::TYPES_WITH_CODE[:ufa], ForestType::TYPES_WITH_CODE[:cf]],
            **required_operator_document_data
          )
          # won't create for this one as not matching forest type
          FactoryBot.create(
            :required_operator_document_fmu,
            forest_types: [ForestType::TYPES_WITH_CODE[:vdc]],
            **required_operator_document_data
          )
          @other_operator.operator_documents.destroy_all
        end

        it "creates related OperatorDocumentCountry and OperatorDocumentFmu if those does not exist" do
          @other_operator.update(fa_id: "fa_id")

          expect(@other_operator.operator_document_countries.size).to eql 1
          operator_document_country = @other_operator.operator_document_countries.first
          expect(operator_document_country.status).to eql "doc_not_provided"

          expect(@other_operator.operator_document_fmus.size).to eql 1
          operator_document_fmu = @other_operator.operator_document_fmus.first
          expect(operator_document_fmu.status).to eql "doc_not_provided"
        end
      end
    end
  end

  describe "Instance methods" do
    before :all do
      valid_status = OperatorDocument.statuses[:doc_valid]
      pending_status = OperatorDocument.statuses[:doc_pending]
      common_data = {
        operator_id: @operator.id,
        required_operator_document_id: @required_operator_document.id,
        public: true
      }

      # Generate one valid operator document and two pending operator documents of each type
      %i[operator_document_country operator_document_fmu operator_document_country].each do |op_doc_type|
        [false, true].each do |public|
          common_data[:public] = public
          common_data[:required_operator_document_id] =
            instance_variable_get("@required_#{op_doc_type}").id

          valid_op_doc = create(op_doc_type, **common_data)
          valid_op_doc.update(status: valid_status)

          pending_op_docs = create_list(op_doc_type, 2, **common_data)
          pending_op_docs.each do |pending_op_doc|
            pending_op_doc.update(status: pending_status)
          end
        end
      end

      # Observations
      4.times do |level|
        severity = create(:severity, level: level)
        create(
          :observation,
          severity: severity,
          operator: @operator,
          country: @country,
          validation_status: "Published (no comments)"
        )
        @operator.reload
      end

      # Operator without documents and observations to check empty values
      @another_operator = create(:operator, country: @country, fa_id: "fa-id")
    end

    before do
      # On each test, we are creating new operator_documents due to the different
      # callbacks which appears on Operator and OperatorDocument. For this, we get the
      # number of required operator_documents on each test
      @operator_documents_required =
        @operator.operator_documents.joins(:required_operator_document).non_signature.required.count.to_f
      @operator_document_countries_required =
        @operator.operator_document_countries.joins(:required_operator_document).non_signature.required.count.to_f
      @operator_document_fmus_required =
        @operator.operator_document_fmus.joins(:required_operator_document).non_signature.required.count.to_f
    end

    describe "#update_valid_documents_percentages" do
      context "when fa_id is present" do
        context "when operator is approved/signed contract" do
          it "update approved percentages" do
            @operator.operator_documents.signature.first.update!(
              status: "doc_valid", document_file: create(:document_file), start_date: Time.zone.today
            ) # sign contract
            @operator.reload

            expect(@operator.score_operator_document.all).to eql(6.0 / @operator_documents_required)
            expect(@operator.score_operator_document.country).to eql(4.0 / @operator_document_countries_required)
            expect(@operator.score_operator_document.fmu).to eql(2.0 / @operator_document_fmus_required)
          end
        end

        context "when operator is not approved/not signed contract" do
          it "update non approved percentages" do
            @operator.operator_documents.signature.first.update!(
              status: "doc_invalid", admin_comment: "invalid", document_file: create(:document_file), start_date: Time.zone.today
            ) # contract invalid
            @operator.reload

            expect(@operator.score_operator_document.all).to eql(3.0 / @operator_documents_required)
            expect(@operator.score_operator_document.country).to eql(2.0 / @operator_document_countries_required)
            expect(@operator.score_operator_document.fmu).to eql(1.0 / @operator_document_fmus_required)
          end
        end

        context "when there are no documents" do
          it "update percentages with a 0 value" do
            ScoreOperatorDocument.recalculate! @another_operator
            @operator.reload

            expect(@another_operator.score_operator_document.all).to eql 0.0
            expect(@another_operator.score_operator_document.country).to eql 0.0
            expect(@another_operator.score_operator_document.fmu).to eql 0.0
          end
        end
      end
    end

    describe "#calculate_observations_scores" do
      context "when there are no visits" do
        it "update observations per visits and score with blank values" do
          ScoreOperatorObservation.recalculate! @another_operator
          @another_operator.reload

          expect(@another_operator.score_operator_observation.obs_per_visit).to eql nil
          expect(@another_operator.score_operator_observation.score).to eql nil
        end
      end

      context "when there are visits" do
        context "all on the same day" do
          it "update observations per visits and calculate the score" do
            ScoreOperatorObservation.recalculate! @operator
            @operator.reload

            expect(@operator.score_operator_observation.obs_per_visit).to eql(4.0)
            expect(@operator.score_operator_observation.score).to eql((4.0 + 2 + 2 + 1) / 9.0)
          end
        end

        context "on different days" do
          before :each do
            severity = create(:severity, level: 1)
            # 4 observations already added in before :all for this operator on the same day
            # adding 2 more on different days, so there will be 3 visits
            create(
              :observation,
              severity: severity,
              operator: @operator,
              country: @country,
              publication_date: 10.days.ago,
              validation_status: "Published (no comments)",
              observation_report: build(:observation_report, publication_date: 10.days.ago)
            )
            create(
              :observation,
              severity: severity,
              operator: @operator,
              country: @country,
              validation_status: "Published (no comments)",
              observation_report: build(:observation_report, publication_date: 3.days.ago)
            )
          end

          it "update observations per visits and calculate the score" do
            ScoreOperatorObservation.recalculate! @operator
            @operator.reload

            visits = 3

            expect(@operator.score_operator_observation.obs_per_visit).to eql(6.0 / visits)
            expect(@operator.score_operator_observation.score).to eql(
              ((4.0 * 1) / visits + (2.0 * 1) / visits + (2.0 * 1) / visits + (1.0 * 3) / visits) / 9.0
            )
          end
        end
      end
    end
  end

  describe "Class methods" do
    describe "#operator_select" do
      it "select operators ordered asd by name" do
        result = Operator.by_name_asc.map { |c| [c.name, c.id] }
        expect(Operator.operator_select).to eq(result)
      end
    end

    describe "#types" do
      it "return operator types" do
        expect(Operator.types).to eql Operator::TYPES
      end
    end

    describe "#translated_types" do
      it "return translated operator types" do
        translated_types = Operator.types.map do |t|
          [I18n.t("operator_types.#{t}", default: t), t.camelize]
        end
        expect(Operator.translated_types).to eql(translated_types)
      end
    end

    describe "#calculate_document_ranking" do
      it "calculate the rank per country of the operators based on their documents" do
        ScoreOperatorDocument.current.joins(:operator)
          .where(operators: {country_id: @country.id}).order(all: :desc) do |score, index|
          expect(score.operator.ranking_operator_document.position).to eql(index + 1)
        end
      end
    end

    describe "#calculate_scores" do
      before do
        Operator.all.map { |operator| ScoreOperatorObservation.recalculate!(operator) }

        5.times do |t|
          country = create(:country)
          operator = create(:operator, country: country, is_active: true, fa_id: "fa_#{t}")
          ScoreOperatorObservation.recalculate!(operator)
          operator.score_operator_observation.update_attribute(:score, t / 10.to_f)
        end
      end
    end
  end
end
