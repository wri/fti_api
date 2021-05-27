require 'csv'

namespace :fix do
  desc 'Fixing operator document generated names'
  task operator_documents_names: :environment do
    count_no_relation = 0
    count_no_operator = 0
    count_wrong_name = 0

    DocumentFile.find_each do |df|
      if df.owner.nil?
        puts "NO relation for document #{df.id}"
        count_no_relation +=1
        next
      end

      operator = df.owner.operator
      if operator.nil?
        puts "NO operator document for #{df.id}"
        count_no_operator += 1
        next
      end

      filename = df.attachment.identifier
      filename_no_ext = File.basename(filename, File.extname(filename))

      next if filename.match(/\d{4}-\d{2}-\d{2}/) # have date in filename then I would say it is ok

      start_name = operator.name[0...30]&.parameterize
      next if df.attachment.identifier.start_with?(start_name)

      new_name = [
        operator.name[0...30]&.parameterize,
        df.owner.required_operator_document.name[0...100]&.parameterize,
        df.created_at.strftime('%Y-%m-%d')
      ].compact.join('-') + File.extname(filename)

      puts "WRONG NAME #{df.attachment.identifier} will be changed to #{new_name}"
      count_wrong_name += 1
    end

    puts "TOTAL COUNT #{DocumentFile.all.count}"
    puts "NO OPERATORS #{count_no_operator}"
    puts "NO RELATION #{count_no_relation}"
    puts "WRONG NAME #{count_wrong_name}"
  end
end
