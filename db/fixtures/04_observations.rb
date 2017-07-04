if Observer.count.zero?
  Rake::Task['import:monitors'].invoke
end

if Operator.count.zero?
  Rake::Task['import:operators'].invoke
end

unless Subcategory.operator.any?
  Rake::Task['import:subcategory_operators'].invoke
end

unless Subcategory.government.any?
  Rake::Task['import:subcategory_governments']
end

if Observation.by_operator.count.zero?
  Rake::Task['import:operator_observations'].invoke
end

if Observation.by_governance.count.zero?
  Rake::Task['import:governance_observations'].invoke
end
