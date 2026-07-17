# frozen_string_literal: true

require "rails_helper"

RSpec.describe ObservationReportStatistic, type: :model do
  let(:country) { create(:country) }
  let(:other_country) { create(:country) }
  let(:observer) { create(:observer) }

  def create_stat(date:, total_count:, country: nil, observer: nil)
    described_class.create!(date: date, country: country, observer: observer, total_count: total_count)
  end

  describe ".at_date and .from_date" do
    before do
      create_stat(date: "2020-01-01", total_count: 5, country: country)
      create_stat(date: "2020-01-05", total_count: 3, country: country, observer: observer)
      create_stat(date: "2020-01-02", total_count: 7)
      create_stat(date: "2020-01-10", total_count: 8, country: country)
    end

    it "returns stats after the date together with the latest stats per country and observer as of the date" do
      expect(described_class.at_date("2019-12-31")).to be_empty

      expect(described_class.at_date("2020-01-07").map { |r| [r.date, r.country_id, r.observer_id, r.total_count] }).to contain_exactly(
        [Date.parse("2020-01-07"), country.id, nil, 5],
        [Date.parse("2020-01-07"), country.id, observer.id, 3],
        [Date.parse("2020-01-07"), nil, nil, 7]
      )

      expect(described_class.from_date("2020-01-07").map { |r| [r.date, r.country_id, r.observer_id, r.total_count] }).to contain_exactly(
        [Date.parse("2020-01-07"), country.id, nil, 5],
        [Date.parse("2020-01-07"), country.id, observer.id, 3],
        [Date.parse("2020-01-07"), nil, nil, 7],
        [Date.parse("2020-01-10"), country.id, nil, 8]
      )
    end
  end

  describe ".by_country" do
    before do
      create_stat(date: "2020-01-01", total_count: 1, country: country)
      create_stat(date: "2020-01-01", total_count: 2, country: other_country)
      create_stat(date: "2020-01-01", total_count: 3)
    end

    it "filters by country handling nil and null values" do
      expect(described_class.by_country(nil).count).to eq(3)
      expect(described_class.by_country("null").pluck(:country_id)).to eq([nil])
      expect(described_class.by_country(country.id.to_s).pluck(:country_id)).to eq([country.id])
    end
  end

  describe ".generate_for_country_and_day" do
    let(:day) { 2.days.ago.to_date }

    def create_report_with_observations(country:)
      travel_to 5.days.ago do
        report = create(:observation_report)
        create(:observation, observation_report: report, country: country)
        report
      end
    end

    it "counts reports of the given country, moving forward dates of unchanged stats" do
      report1 = create_report_with_observations(country: country)
      report2 = create_report_with_observations(country: country)
      create_report_with_observations(country: other_country)

      described_class.generate_for_country_and_day(country.id, day - 1)

      total_row = described_class.find_by(country: country, observer: nil)
      expect(total_row.date).to eq(day - 1)
      expect(total_row.total_count).to eq(2)
      expect(described_class.find_by(country: country, observer: report1.observers.first).total_count).to eq(1)
      expect(described_class.find_by(country: country, observer: report2.observers.first).total_count).to eq(1)
      expect(described_class.where(country: other_country)).to be_empty

      # generating the next day with unchanged counts moves the dates forward
      expect {
        described_class.generate_for_country_and_day(country.id, day)
      }.not_to change(described_class, :count)
      expect(described_class.where(country: country).pluck(:date)).to all(eq(day))

      # nil country counts reports of all countries
      described_class.generate_for_country_and_day(nil, day)
      expect(described_class.find_by(country: nil, observer: nil).total_count).to eq(3)
    end
  end
end
