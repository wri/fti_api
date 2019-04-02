namespace :environment_migration do
  desc 'Generates a json with the previous database'
  task :export, [:date] => :environment do |_task, args|
    return unless Rails.env.staging?
    return unless args[:date].present?
    date = args[:date] # Basedate: 2019-08-28

    puts "Starting to migrate staging for date #{date}"
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET session_replication_role = 'replica'")
      # Remove indexes
      puts "Removing Indexes"
      # ActiveRecord::Base.connection.execute('DROP INDEX index_req_op_doc_group_id;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_operator_translations_on_operator_id;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_64b55c0cec158f1717cc5d775ae87c7a48f1cc59;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_eed74ed5a0934f32c4b075e5beee98f1ebf34d19;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_fmu_translations_on_fmu_id;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_fmu_operators_on_fmu_id_and_operator_id;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_fmu_operators_on_operator_id_and_fmu_id;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_operator_documents_on_required_operator_document_id;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_operator_documents_on_operator_id;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_operator_documents_on_fmu_id;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_operator_document_annexes_on_operator_document_id;')
      # ActiveRecord::Base.connection.execute('DROP INDEX index_operator_document_annexes_on_user_id;')

      # Remove old records
      puts "Removing old records"

      ActiveRecord::Base.connection.execute("DELETE FROM observation_documents where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM observations where created_at < '#{date}'")

      ActiveRecord::Base.connection.execute("DELETE FROM operator_document_annexes where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM operator_documents where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM required_operator_document_translations where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM required_operator_documents where created_at < '#{date}'")

      ActiveRecord::Base.connection.execute("DELETE FROM fmu_operators where created_at < '#{date}'")

      ActiveRecord::Base.connection.execute("DELETE FROM fmu_translations where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM fmus where created_at < '#{date}'")

      ActiveRecord::Base.connection.execute("DELETE FROM api_keys where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM users where created_at < '#{date}'")

      ActiveRecord::Base.connection.execute("DELETE FROM sawmills")
      ActiveRecord::Base.connection.execute("DELETE FROM operator_translations where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM operators where created_at < '#{date}'")

      # Update ids
      puts "Update Ids"
      ActiveRecord::Base.connection.execute("UPDATE users set id = id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE operators set id = id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE operator_translations set id = id + 10000, operator_id = operator_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE fmus set id = id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE fmu_translations set id = id + 10000, fmu_id = fmu_id + 10000")
      #ActiveRecord::Base.connection.execute("UPDATE required_operator_document_groups set id = id + 10000")
      #ActiveRecord::Base.connection.execute("UPDATE required_operator_document_group_translations set id = id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE fmu_operators set id = id + 10000, fmu_id = fmu_id + 10000, operator_id = operator_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE required_operator_documents set id = id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE required_operator_document_translations set id = id + 10000, required_operator_document_id = required_operator_document_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE operator_documents set id = id + 10000, required_operator_document_id = required_operator_document_id + 10000, fmu_id = fmu_id + 10000, operator_id = operator_id + 10000, user_id = user_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE operator_document_annexes set id = id + 10000, operator_document_id = operator_document_id + 10000, user_id = user_id + 10000")

      ActiveRecord::Base.connection.execute("SET session_replication_role = 'origin'")


      require 'fileutils'

      # Update folder names
      puts "Renaming folders"
      # Operators
      Dir.chdir(Rails.root.join('public', 'uploads', 'operator', 'logo')) do
        folders = Dir.glob('*').select { |f| File.directory? f }
        folders.each do |f|
          operator = Operator.where(id: f.to_i + 10000).first
          if operator.present?
            File.rename "./#{f}", "./#{(f.to_i + 10000).to_s}"
          else
            FileUtils.rm_r "./#{f}"
          end
        end
      end

      # Operator documents
      Dir.chdir(Rails.root.join('public', 'uploads', 'operator_document', 'attachment')) do
        folders = Dir.glob('*').select { |f| File.directory? f }
        folders.each do |f|
          operator_document = OperatorDocument.where(id: f.to_i + 10000).first
          if operator_document.present?
            File.rename "./#{f}", "./#{(f.to_i + 10000).to_s}"
          else
            FileUtils.rm_r "./#{f}"
          end
        end
      end

      # Annexes
      Dir.chdir(Rails.root.join('public', 'uploads', 'operator_document_annex', 'attachment')) do
        folders = Dir.glob('*').select { |f| File.directory? f }
        folders.each do |f|
          operator_document_annex = OperatorDocumentAnnex.where(id: f.to_i + 10000).first
          if operator_document_annex.present?
            File.rename "./#{f}", "./#{(f.to_i + 10000).to_s}"
          else
            FileUtils.rm_r "./#{f}"
          end
        end
      end

      # Create pg_dump
      puts "Creating dump"
      sh "pg_dump --data-only -U postgres -d fti_api_staging -t public.operators -t public.operator_translations -t public.fmus -t public.fmu_translations -t public.required_operator_document_groups -t public.required_operator_document_group_translations -t public.required_operator_documents -t public.required_operator_document_translations -t public.fmu_operators -t public.operator_documents -t public.operator_document_annexes -t public.users --file staging#{Date.today.to_i.to_s}.dump"
    end
  end
end