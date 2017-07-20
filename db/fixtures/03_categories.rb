if Category.count.zero?
  Rake::Task['import:categories'].invoke unless Category.any?
end
