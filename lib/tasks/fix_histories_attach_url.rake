namespace :operator_documents_histories do
  desc 'Checks for OperatorDocumentHistories with wrong attachment urls and fixs it'
  task fix_urls: :environment do
    broken_urls = []
    OperatorDocumentHistory.unscoped.each do |odh|
      if odh.document_file.present?
       if odh.document_file.attachment.url.split('.').count == 1
          broken_urls.push(odh.id)
        end
      end
    end
    puts 'broken_urls.count'
    puts broken_urls.count

    broken_urls.each do |odh_id|
      odh = OperatorDocumentHistory.unscoped.find(odh_id)
      if odh.operator_document.attachment&.split('.').count == 2
        puts 'fixing ' + odh.id.to_s
        new_file_name = odh.document_file.file_name + '.' + odh.operator_document.attachment&.split('.')&.last
        odh.document_file.file_name = new_file_name
        odh.document_file.attachment = new_file_name
        odh.document_file.save!
      end
    end
  
    after_broken_urls = []
    OperatorDocumentHistory.unscoped.each do |odh|
      if odh.document_file.present?
        if odh.document_file.attachment.url.split('.').count == 1
          after_broken_urls.push(odh.id)
        end
      end
    end
    puts 'after_broken_urls.count'
    puts after_broken_urls.count
  end
end