namespace :operator_documents_histories do
  desc 'Checks if current ODHs status match with current OD status'
  task check_sync: :environment do
    unsync_docs = {}
    Operator.all.each do |opt|
      docs = []
      odhs = OperatorDocumentHistory.from_operator_at_date(opt, Date.today)
      odhs.each do |odh|
          od = odh.operator_document
          unless odh.status == od.status
              docs.push(od.id)
          end
      end
      unsync_docs[opt.id] = docs if docs.count >= 1
    end
    puts unsync_docs
  end

  desc 'Checks if current ODHs status match with current OD status for a given operator'
  task :check_sync_opt, [:id] => :environment do |_, args|
    unsync_docs = []
    opt = Operator.find(args[:id])
    odhs = OperatorDocumentHistory.from_operator_at_date(opt, Date.today)
    odhs.each do |odh|
        od = odh.operator_document
        unless odh.status == od.status
            unsync_docs.push(od.id)
        end
    end
    puts unsync_docs
  end

  desc 'Creates new ODHs for those unsync'
  task resync: :environment do
    Operator.all.each do |opt|
      odhs = OperatorDocumentHistory.from_operator_at_date(opt, Date.today)
      odhs.each do |odh|
          od = odh.operator_document
          unless odh.status == od.status
              od.updated_at = DateTime.now
              od.save!
              ScoreOperatorDocument.recalculate!(opt)
          end
      end
    end
  end

  desc 'Creates new ODHs for those unsync for a given operator'
  task :resync_opt, [:id] => :environment do |_, args|
    opt = Operator.find(args[:id])
    odhs = OperatorDocumentHistory.from_operator_at_date(opt, Date.today)
    odhs.each do |odh|
        od = odh.operator_document
        unless odh.status == od.status
            od.updated_at = DateTime.now
            od.save!
            ScoreOperatorDocument.recalculate!(opt)
        end
    end
  end

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