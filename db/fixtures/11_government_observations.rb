Rake::Task["import:government_observations"].invoke unless Observation.government.any?
