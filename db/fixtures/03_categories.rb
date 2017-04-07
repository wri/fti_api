if Category.count.zero?
  Rake::Task['import_categories_csv:create_categories'].invoke
end
