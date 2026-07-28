# frozen_string_literal: true

require "rails_helper"

RSpec.describe OperatorDocumentStatistic, type: :model do
  let(:country) { create(:country) }
  let(:other_country) { create(:country) }

  def create_stat(date:, valid_count: 0, country: nil, group: nil, document_type: nil)
    described_class.create!(
      date: date,
      country: country,
      required_operator_document_group: group,
      document_type: document_type,
      valid_count: valid_count
    )
  end

  describe ".at_date and .from_date" do
    before do
      create_stat(date: "2020-01-01", valid_count: 5, country: country)
      create_stat(date: "2020-01-05", valid_count: 3, country: country, document_type: "fmu")
      create_stat(date: "2020-01-02", valid_count: 7)
      create_stat(date: "2020-01-10", valid_count: 8, country: country)
    end

    it "returns stats after the date together with the latest stats per dimensions as of the date" do
      expect(described_class.at_date("2019-12-31")).to be_empty

      expect(described_class.at_date("2020-01-07").map { |r| [r.date, r.country_id, r.document_type, r.valid_count] }).to contain_exactly(
        [Date.parse("2020-01-07"), country.id, nil, 5],
        [Date.parse("2020-01-07"), country.id, "fmu", 3],
        [Date.parse("2020-01-07"), nil, nil, 7]
      )

      expect(described_class.from_date("2020-01-07").map { |r| [r.date, r.country_id, r.document_type, r.valid_count] }).to contain_exactly(
        [Date.parse("2020-01-07"), country.id, nil, 5],
        [Date.parse("2020-01-07"), country.id, "fmu", 3],
        [Date.parse("2020-01-07"), nil, nil, 7],
        [Date.parse("2020-01-10"), country.id, nil, 8]
      )
    end
  end

  describe ".by_country" do
    before do
      create_stat(date: "2020-01-01", country: country)
      create_stat(date: "2020-01-01", country: other_country)
      create_stat(date: "2020-01-01")
    end

    it "filters by country handling nil and null values" do
      expect(described_class.by_country(nil).count).to eq(3)
      expect(described_class.by_country("null").pluck(:country_id)).to eq([nil])
      expect(described_class.by_country(country.id.to_s).pluck(:country_id)).to eq([country.id])
    end
  end

  describe ".by_required_operator_document_group" do
    let(:group) { create(:required_operator_document_group) }
    let(:other_group) { create(:required_operator_document_group) }

    before do
      create_stat(date: "2020-01-01", group: group)
      create_stat(date: "2020-01-01", group: other_group)
      create_stat(date: "2020-01-01")
    end

    it "filters by single and multiple groups handling the null value" do
      expect(described_class.by_required_operator_document_group(group.id).pluck(:required_operator_document_group_id)).to eq([group.id])
      expect(described_class.by_required_operator_document_group("null").pluck(:required_operator_document_group_id)).to eq([nil])
      expect(described_class.by_required_operator_document_group("null", group.id).pluck(:required_operator_document_group_id)).to contain_exactly(nil, group.id)
    end
  end

  describe "#valid_and_expired_count" do
    it "sums valid and expired counts" do
      expect(described_class.new(valid_count: 2, expired_count: 3).valid_and_expired_count).to eq(5)
    end
  end

  describe ".generate_for_country_and_day" do
    let(:day) { 2.days.ago.to_date }

    def create_document(status, **attributes)
      doc = travel_to(5.days.ago) { create(:operator_document_country, **attributes) }
      # later than creation, so the status change history is the latest one
      travel_to(4.days.ago) { doc.update!(status: status) }
      doc
    end

    it "counts document statuses of the given country, moving forward dates of unchanged stats" do
      doc = create_document("doc_valid")
      create_document("doc_pending") # different country
      doc_country = doc.required_operator_document.country
      group = doc.required_operator_document.required_operator_document_group

      described_class.generate_for_country_and_day(doc_country.id, day - 1)

      rollup = described_class.find_by(
        country: doc_country, required_operator_document_group: nil, document_type: nil, fmu_forest_type: nil
      )
      expect(rollup.date).to eq(day - 1)
      expect(rollup.valid_count).to eq(1)
      expect(rollup.pending_count).to eq(0)

      sliced = described_class.find_by(
        country: doc_country, required_operator_document_group: group, document_type: "country", fmu_forest_type: nil
      )
      expect(sliced.valid_count).to eq(1)

      # generating the next day with unchanged counts moves the dates forward
      expect {
        described_class.generate_for_country_and_day(doc_country.id, day)
      }.not_to change(described_class, :count)
      expect(described_class.where(country: doc_country).pluck(:date)).to all(eq(day))

      # nil country counts documents of all countries
      described_class.generate_for_country_and_day(nil, day)
      all_countries_rollup = described_class.find_by(
        country: nil, required_operator_document_group: nil, document_type: nil, fmu_forest_type: nil
      )
      expect(all_countries_rollup.valid_count).to eq(1)
      expect(all_countries_rollup.pending_count).to eq(1)
    end
  end
end
