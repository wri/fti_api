if Species.count.zero?
  Rake::Task['import_species_csv:create_species'].invoke
end
