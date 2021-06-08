require 'csv'

namespace :fix do
  desc 'Fixing operator document generated names'
  task operator_documents_names: :environment do
    count_no_relation = 0
    count_no_operator = 0
    count_wrong_name = 0
    count_file_not_exists = 0

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
      next if filename.match(/\d{4}-\d{2}-\d{2}/) # have date in filename then I would say it is ok

      start_name = operator.name[0...30]&.parameterize
      next if df.attachment.identifier.start_with?(start_name)

      new_name = [
        operator.name[0...30]&.parameterize,
        df.owner.required_operator_document.name[0...100]&.parameterize,
        df.created_at.strftime('%Y-%m-%d')
      ].compact.join('-') + File.extname(filename)

      file_dirname = File.dirname(df.attachment.file.file)
      new_file_path = File.join(file_dirname, new_name)

      puts "WRONG NAME for #{df.id} #{df.attachment.identifier} will be changed to #{new_name}"
      count_wrong_name += 1

      unless df.attachment.present?
        puts "NO file for #{df.id}"
        count_file_not_exists += 1
        next
      end

      if ENV["FOR_REAL"]
        df.attachment.file.move!(new_file_path)
        df.update_columns(attachment: new_name)
      end
    end

    puts "TOTAL COUNT #{DocumentFile.all.count}"
    puts "NO OPERATORS #{count_no_operator}"
    puts "NO RELATION #{count_no_relation}"
    puts "WRONG NAME #{count_wrong_name}"
    puts "WRONG FILE DOES NOT EXIST #{count_file_not_exists}"
  end
end
