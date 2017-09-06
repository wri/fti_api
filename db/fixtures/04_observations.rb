Rake::Task['import:monitors'].invoke                 unless Observer.any?
Rake::Task['import:operators'].invoke                unless Operator.any?
Rake::Task['import:fmus'].invoke                     unless Fmu.any?
Rake::Task['import:subcategory_operators'].invoke    unless Subcategory.operator.any?
Rake::Task['import:subcategory_governments'].invoke  unless Subcategory.government.any?
Rake::Task['import:laws'].invoke                     
Rake::Task['import:operator_observations'].invoke    unless Observation.operator.any?
Rake::Task['import:government_observations'].invoke  unless Observation.government.any?
Rake::Task['import:operator_countries'].invoke       unless Operator.where('country_id is not null').exists?
Rake::Task['import:operator_document_types'].invoke  unless RequiredOperatorDocumentGroup.any?
Rake::Task['import:operator_documents'].invoke       unless OperatorDocument.any?