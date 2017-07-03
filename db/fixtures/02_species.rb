if Species.count.zero?
  Rake::Task['import:species'].invoke
end
