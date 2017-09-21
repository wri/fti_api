Rake::Task['import:operator_observations'].invoke    unless Observation.operator.any?
