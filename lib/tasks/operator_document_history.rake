namespace :operator_documents_histories do
  desc "Checks if current ODHs status match with current OD status"
  task check_sync: :environment do
    unsync_docs = {}
    Operator.all.each do |opt|
      docs = []
      odhs = OperatorDocumentHistory.from_operator_at_date(opt.id, Time.zone.today)
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

  desc "Checks if current ODHs status match with current OD status for a given operator"
  task :check_sync_opt, [:id] => :environment do |_, args|
    unsync_docs = []
    opt = Operator.find(args[:id])
    odhs = OperatorDocumentHistory.from_operator_at_date(opt.id, Time.zone.today)
    odhs.each do |odh|
      od = odh.operator_document
      unless odh.status == od.status
        unsync_docs.push(od.id)
      end
    end
    puts unsync_docs
  end

  desc "Creates new ODHs for those unsync"
  task resync: :environment do
    Operator.all.each do |opt|
      odhs = OperatorDocumentHistory.from_operator_at_date(opt.id, Time.zone.today)
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

  desc "Creates new ODHs for those unsync for a given operator"
  task :resync_opt, [:id] => :environment do |_, args|
    opt = Operator.find(args[:id])
    odhs = OperatorDocumentHistory.from_operator_at_date(opt.id, Time.zone.today)
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
