Rake::Task['import:monitors'].invoke                 unless Observer.any?
Rake::Task['import:operators'].invoke                unless Operator.any?
Rake::Task['import:subcategory_operators'].invoke    unless Subcategory.operator.any?
Rake::Task['import:subcategory_governments'].invoke  unless Subcategory.government.any?
Rake::Task['import:operator_observations'].invoke    unless Observation.operator.any?
Rake::Task['import:government_observations'].invoke  unless Observation.government.any?


