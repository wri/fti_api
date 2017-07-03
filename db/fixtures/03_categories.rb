if Category.count.zero?
  Rake::Task['import:categories'].invoke
end
