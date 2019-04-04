namespace :environment_migration do
  desc 'Generates a json with the previous database'
  task :export, [:date] => :environment do |_task, args|
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Logger.new STDOUT
    return unless Rails.env.staging?
    return unless args[:date].present?
    date = args[:date] # Basedate: 2019-08-28

    puts "Starting to migrate staging for date #{date}"
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET session_replication_role = 'replica'")

      # Removing specific objects for duplicated entries
      puts "Removing specific records"
      ActiveRecord::Base.connection.execute("DELETE FROM api_keys where user_id in (63, 67, 69)")
      ActiveRecord::Base.connection.execute("DELETE FROM user_permissions where user_id in (63, 67, 69)")
      ActiveRecord::Base.connection.execute("DELETE FROM users where id in (63, 67, 69)")

      # Updating specific entries
      puts 'Updating specific entries'
      ActiveRecord::Base.connection.execute("UPDATE operator_documents set user_id = 27 where user_id = 63")
      ActiveRecord::Base.connection.execute("UPDATE operator_document_annexes set user_id = 27 where user_id = 63")

      ActiveRecord::Base.connection.execute("UPDATE operator_documents set user_id = 69 where user_id = 107")
      ActiveRecord::Base.connection.execute("UPDATE operator_document_annexes set user_id = 69 where user_id = 107")

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

      ActiveRecord::Base.connection.execute("DELETE FROM user_permissions where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM api_keys where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM users where created_at < '#{date}'")

      ActiveRecord::Base.connection.execute("DELETE FROM sawmills")
      ActiveRecord::Base.connection.execute("DELETE FROM operator_translations where created_at < '#{date}'")
      ActiveRecord::Base.connection.execute("DELETE FROM operators where created_at < '#{date}'")

      # Update ids
      puts "Update Ids"
      ActiveRecord::Base.connection.execute("UPDATE user_permissions set id = id + 10000, user_id = user_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE api_keys set id = id + 10000, user_id = user_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE users set id = id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE operators set id = id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE operator_translations set id = id + 10000, operator_id = operator_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE fmus set id = id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE fmu_translations set id = id + 10000, fmu_id = fmu_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE fmu_operators set id = id + 10000, fmu_id = fmu_id + 10000, operator_id = operator_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE required_operator_documents set id = id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE required_operator_document_translations set id = id + 10000, required_operator_document_id = required_operator_document_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE operator_documents set id = id + 10000, required_operator_document_id = required_operator_document_id + 10000, fmu_id = fmu_id + 10000, operator_id = operator_id + 10000, user_id = user_id + 10000")
      ActiveRecord::Base.connection.execute("UPDATE operator_document_annexes set id = id + 10000, operator_document_id = operator_document_id + 10000, user_id = user_id + 10000")


      # HACK
      puts "Removing existing required operator document groups"
      ActiveRecord::Base.connection.execute("DELETE FROM required_operator_document_groups where id <> 11")
      ActiveRecord::Base.connection.execute("DELETE FROM required_operator_document_group_translations where required_operator_document_group_id <> 11")



      ActiveRecord::Base.connection.execute("SET session_replication_role = 'origin'")


      require 'fileutils'

      # Update folder names
      # puts "Renaming folders"
      # # Operators
      # Dir.chdir(Rails.root.join('public', 'uploads', 'operator', 'logo')) do
      #   folders = Dir.glob('*').select { |f| File.directory? f }
      #   folders.each do |f|
      #     operator = Operator.where(id: f.to_i + 10000).first
      #     if operator.present?
      #       File.rename "./#{f}", "./#{(f.to_i + 10000).to_s}"
      #     else
      #       FileUtils.rm_r "./#{f}"
      #     end
      #   end
      # end
      #
      # # Operator documents
      # Dir.chdir(Rails.root.join('public', 'uploads', 'operator_document', 'attachment')) do
      #   folders = Dir.glob('*').select { |f| File.directory? f }
      #   folders.each do |f|
      #     operator_document = OperatorDocument.where(id: f.to_i + 10000).first
      #     if operator_document.present?
      #       File.rename "./#{f}", "./#{(f.to_i + 10000).to_s}"
      #     else
      #       FileUtils.rm_r "./#{f}"
      #     end
      #   end
      # end
      #
      # # Annexes
      # Dir.chdir(Rails.root.join('public', 'uploads', 'operator_document_annex', 'attachment')) do
      #   folders = Dir.glob('*').select { |f| File.directory? f }
      #   folders.each do |f|
      #     operator_document_annex = OperatorDocumentAnnex.where(id: f.to_i + 10000).first
      #     if operator_document_annex.present?
      #       File.rename "./#{f}", "./#{(f.to_i + 10000).to_s}"
      #     else
      #       FileUtils.rm_r "./#{f}"
      #     end
      #   end
      # end
    end

    # Create pg_dump
    puts "Creating dump"
    sh "pg_dump --data-only -U postgres -d fti_api_staging -Fc -t public.operators -t public.operator_translations -t public.fmus -t public.fmu_translations -t public.required_operator_document_groups -t public.required_operator_document_group_translations -t public.required_operator_documents -t public.required_operator_document_translations -t public.fmu_operators -t public.operator_documents -t public.operator_document_annexes -t public.users -t public.api_keys -t public.user_permissions --file staging.dump"
  end

  desc 'Imports a file into production'
  task :import, [:date, :file] => :environment do |_task, args|
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Logger.new STDOUT

    return unless Rails.env.production?
    return unless args[:date].present?
    date = args[:date] # Basedate: 2019-08-28
    file = args[:file] || 'staging.dump'

    # Hacks
    # Deal with old operators

    Operator.find(557).destroy!
    Operator.find(371).destroy!
    Operator.find(374).destroy!
    Operator.find(377).destroy!
    Operator.find(378).destroy!
    Operator.find(376).destroy!
    Operator.find(372).destroy!
    Operator.find(373).destroy!
    Operator.find(375).destroy!
    Operator.find(379).destroy!
    Operator.find(380).destroy!

    # Delete docs for: 387, 491, 505
    # 555 - Replace observations

    # Restore database
    sh "pg_restore -v -d fti_api_production #{file}"

    ActiveRecord::Base.transaction do

      operators_to_remove = []
      fmus_to_remove = []
      Operator.where("country_id = 45 and created_at < '#{date}'").find_each do |operator|
        operator.all_observations.find_each do |obs|
          if obs.fmu_id
            fmu = Fmu.find(obs.fmu_id)
            new_fmu = Fmu.with_translations.where(name: fmu.name).order(:id).last
            if new_fmu.id != fmu.id
              obs.fmu = new_fmu
              obs.save
              fmus_to_remove << fmu.id
            end
          end
          new_operator = Operator.with_translations.where(name: operator.name).order(:id).last
          next if new_operator.id == operator.id
          obs.operator = new_operator
          obs.save
          operators_to_remove << operator.id
        end
      end

      operators_to_remove.uniq!
      fmus_to_remove.uniq!

      # Remove deleted operators
      operators_to_remove.each do |operator_id|
        Operator.find(operator_id).destroy!
      end

      # Remove deleted fmus
      fmus_to_remove.each do |fmu_id|
        ActiveRecord::Base.connection.execute("DELETE FROM operator_documents where fmu_id = '#{fmu_id}'")
        Fmu.find(fmu_id).destroy!
      end

      # Remove duplicated operators
      Operator.where("country_id = 45 and id < 10000").find_each do |operator|
        next if operator.observations.any?
        operator.destroy!
      end

      # Remove duplicated fmus
      Fmu.where("country_id = 45 and id < 10000").find_each do |fmu|
        next if fmu.observations.any?
        ActiveRecord::Base.connection.execute("DELETE FROM operator_documents where fmu_id = '#{fmu.id}'")
        fmu.destroy!
      end

      # Create the documents for operators
      Operator.where("country_id = 45").find_each do |operator|
        operator.rebuild_documents
      end


      puts "finished"
    end
  end
end