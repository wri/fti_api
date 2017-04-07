if Observer.count.zero?
  Rake::Task['import_monitors_csv:create_monitors'].invoke
end

if Operator.count.zero?
  Rake::Task['import_operators_csv:create_operators'].invoke
end

if Law.count.zero?
  Rake::Task['import_laws_csv:create_laws'].invoke
end

if AnnexOperator.count.zero?
  Rake::Task['import_annex_operators_csv:create_annex_operators'].invoke
end

if AnnexGovernance.count.zero?
  Rake::Task['import_annex_governance_csv:create_annex_governance'].invoke
end

if Observation.by_operator.count.zero?
  Rake::Task['import_operator_observations_csv:create_operator_observation'].invoke
end

if Observation.by_governance.count.zero?
  Rake::Task['import_governance_observations_csv:create_governance_observation'].invoke
end
