namespace :data_migrations do
  task report_mission_type: :environment do
    csv_file = ENV["CSV_FILE"] || "tmp/data_migrations_report_mission_type.csv"
    for_real = ENV["FOR_REAL"] == "true"
    verbose = ENV["VERBOSE"] == "true"
    puts "DRY RUN" unless for_real

    observer_type_to_mission_type = {
      "Mandated" => "mandated",
      "SemiMandated" => "semi_mandated",
      "Government" => "government",
      "External" => "external"
    }

    missions = {}
    CSV.foreach(csv_file, headers: true) do |row|
      id = row["id"].to_i
      mission_type = row["mission_type"]
      missions[id] = mission_type
    end

    migration_report = []
    migration_report << ["report_id", "csv_mission_type", "inferred_mission_types", "mismatched?", "saved_mission_type", "report_deleted?", "notes"]

    puts "Populating observation report mission types..."

    ObservationReport.with_deleted.order(id: :asc).find_each do |report|
      observer_types = report.observers.pluck(:observer_type).uniq
      observer_types = report.observations.with_deleted.flat_map { |o| Observer.where(id: o.observer_observations.with_deleted.pluck(:observer_id)).pluck(:observer_type) }.uniq if observer_types.empty?
      inferred_mission_types = observer_types.map { |type| observer_type_to_mission_type[type] }
      inferred_mission_type = inferred_mission_types.first
      csv_mission_type = missions[report.id]
      mismatched = csv_mission_type && inferred_mission_types.any? && inferred_mission_types.exclude?(csv_mission_type)
      mission_type = csv_mission_type || inferred_mission_type

      message = "WARNING: no mission type" if mission_type.nil?
      message = "WARNING: no inferred mission type (no observers) but taking from csv" if inferred_mission_types.empty? && csv_mission_type
      message = "WARNING: mission type from CSV does not match inferred mission type" if mismatched

      migration_report << [report.id, csv_mission_type, inferred_mission_types.join("; "), mismatched ? "true" : nil, mission_type, report.deleted? ? "true" : nil, message]
      puts migration_report.last.join(", ") if verbose
      next if mission_type.nil?

      report.mission_type = mission_type
      report.save!(validate: false) if for_real
    end

    CSV.open("tmp/data_migrations_report_mission_type_report.csv", "w") do |csv|
      migration_report.each { |row| csv << row }
    end
    puts "Wrote tmp/data_migrations_report_mission_type_report.csv"
  end
end
