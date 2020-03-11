namespace :operator_documents do
  desc 'Destroys operator documents whose ROD have been destroyed'
  task destroy: :environment do
    puts 'Going to destroy operator documents'

    RequiredOperatorDocument.only_deleted.find_each do |rod|
      rod.operator_documents.update_all deleted_at: Time.now
    end
  end
end