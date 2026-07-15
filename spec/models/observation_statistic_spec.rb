# frozen_string_literal: true

require "rails_helper"

RSpec.describe ObservationStatistic, type: :model do
  describe ".query_dashboard_report" do
    # observations are expensive to create and the query only reads observation_histories,
    # so prebuild them once and let examples create just the history rows
    before(:all) do
      @country = create(:country)
      @other_country = create(:country)
      @observations = create_list(:observation, 5, country: @country)
    end

    let(:country) { @country }
    let(:other_country) { @other_country }
    let(:observations) { @observations }

    # midday timestamp, as the query counts a history from the day after its date
    def add_history(observation, status, date, country: observation.country)
      create(:observation_history, observation: observation, country: country, validation_status: status, observation_updated_at: Time.zone.parse("#{date} 12:00"))
    end

    def query(search = {})
      described_class.query_dashboard_report(
        {date_gteq: "2020-01-01", date_lteq: "2020-01-10"}.merge(search)
      ).to_a
    end

    def row_for(result, date, country_id)
      result.find { |r| r.date == Date.parse(date) && r.country_id == country_id }
    end

    it "returns counts per validation status as of the end date, with 0 for statuses without observations" do
      add_history(observations[0], "Created", "2020-01-01")
      add_history(observations[1], "Created", "2020-01-01")
      add_history(observations[1], "Approved", "2020-01-05")
      add_history(observations[2], "Published (no comments)", "2020-01-01")
      add_history(observations[3], "Published (not modified)", "2020-01-01")
      add_history(observations[4], "Published (modified)", "2020-01-01")

      row = row_for(query, "2020-01-10", country.id)

      expect(row).to be_present
      expect(row).to have_attributes(
        created: 1,
        approved: 1,
        published_no_comments: 1,
        published_not_modified: 1,
        published_modified: 1,
        published_all: 3,
        rejected: 0,
        total_count: 5
      )
    end

    it "returns a rollup row aggregating all countries" do
      add_history(observations[0], "Created", "2020-01-01")
      add_history(observations[1], "Created", "2020-01-01", country: other_country)

      result = query

      expect(row_for(result, "2020-01-10", nil)).to have_attributes(created: 2, total_count: 2)
      expect(row_for(result, "2020-01-10", country.id).created).to eq(1)
      expect(row_for(result, "2020-01-10", other_country.id).created).to eq(1)
    end

    it "filters by the published all status combining all published statuses" do
      add_history(observations[0], "Published (no comments)", "2020-01-01")
      add_history(observations[1], "Published (not modified)", "2020-01-01")
      add_history(observations[2], "Published (modified)", "2020-01-01")
      add_history(observations[3], "Created", "2020-01-01")

      row = row_for(query(validation_status_eq: "789"), "2020-01-10", country.id)

      expect(row).to have_attributes(published_all: 3, total_count: 3)
    end

    it "filters by operator" do
      add_history(observations[0], "Created", "2020-01-01")
      add_history(observations[1], "Created", "2020-01-01")

      row = row_for(query(operator_id_eq: observations[0].operator_id.to_s), "2020-01-10", country.id)

      expect(row).to have_attributes(created: 1, total_count: 1, operator_id: observations[0].operator_id)
    end

    it "does not count soft deleted histories" do
      add_history(observations[0], "Created", "2020-01-01").destroy
      add_history(observations[1], "Created", "2020-01-01")
      add_history(observations[1], "Approved", "2020-01-05").destroy

      result = query

      # deleting the latest history hides the observation instead of reverting it
      expect(row_for(result, "2020-01-02", country.id)).to have_attributes(created: 1, total_count: 1)
      expect(row_for(result, "2020-01-10", country.id)).to be_nil
    end

    it "filters by country, including the all countries option" do
      add_history(observations[0], "Created", "2020-01-01")
      add_history(observations[1], "Created", "2020-01-01", country: other_country)

      result = query(by_country: country.id.to_s)
      expect(result.map(&:country_id).uniq).to contain_exactly(country.id)

      result = query(by_country: "null")
      expect(result.map(&:country_id).uniq).to eq([nil])
      expect(row_for(result, "2020-01-10", nil)).to have_attributes(created: 2, total_count: 2)
    end

    it "filters by date, counting the latest status of each observation as of each date" do
      observations[0..3].each { |obs| add_history(obs, "Created", "2020-01-01") }
      add_history(observations[3], "Approved", "2020-01-04")
      observations[0..2].each { |obs| add_history(obs, "Approved", "2020-01-07") }
      add_history(observations[0], "Rejected", "2020-01-15")

      result = query(date_gteq: "2020-01-01", date_lteq: "2020-01-10")

      expect(result.map(&:date)).to all(be_between(Date.parse("2020-01-01"), Date.parse("2020-01-10")))
      expect(row_for(result, "2020-01-02", country.id)).to have_attributes(created: 4, total_count: 4)
      expect(row_for(result, "2020-01-05", country.id)).to have_attributes(created: 3, approved: 1, total_count: 4)
      expect(row_for(result, "2020-01-08", country.id)).to have_attributes(approved: 4, total_count: 4)
      expect(row_for(result, "2020-01-10", country.id)).to have_attributes(approved: 4, total_count: 4)
    end

    it "returns the same counts for a date regardless of the date range" do
      add_history(observations[0], "Created", "2020-01-01")
      add_history(observations[1], "Approved", "2020-01-05")

      row_from_full_range = row_for(query, "2020-01-06", country.id)
      row_from_boundary_range = row_for(query(date_gteq: "2020-01-06"), "2020-01-06", country.id)

      expect(row_from_boundary_range).to be_present
      expect(row_from_full_range).to be_present
      expect(row_from_full_range).to have_attributes(
        created: row_from_boundary_range.created,
        approved: row_from_boundary_range.approved,
        total_count: row_from_boundary_range.total_count
      )
    end
  end
end
