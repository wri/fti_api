namespace :environment_migration_v2 do
  desc 'Generates a sql dump with the previous database'
  task export: :environment do |_task, args|
    MAX_ID = 100_000
    MIN_ID = 20_000
    country_ids = "(188, 53)"
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Logger.new STDOUT
    return unless Rails.env.production_secondary?

    puts "Starting to migrate secondary database for ids: #{MAX_ID}"
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET session_replication_role = 'replica'")

      # Removing old api_keys
      puts "Removing specific records"
      ActiveRecord::Base.connection.execute("DELETE FROM api_keys where user_id < #{MAX_ID}")
      ActiveRecord::Base.connection.execute("DELETE FROM user_permissions where user_id < #{MAX_ID}")
      ActiveRecord::Base.connection.execute("DELETE FROM users where id < #{MAX_ID}")

      # Remove old records
      puts "Removing old records"

      ActiveRecord::Base.connection.execute("DELETE FROM operator_document_annexes where id < #{MAX_ID}")

      ActiveRecord::Base.connection.execute("DELETE FROM operator_documents where id < #{MAX_ID}")

      ActiveRecord::Base.connection.execute("DELETE FROM required_operator_document_translations where id < #{MAX_ID}")
      ActiveRecord::Base.connection.execute("DELETE FROM required_operator_documents where id < #{MAX_ID}")

      ActiveRecord::Base.connection.execute("DELETE FROM fmu_operators where id < #{MAX_ID}")

      ActiveRecord::Base.connection.execute("DELETE FROM fmu_translations where id < #{MAX_ID}")
      ActiveRecord::Base.connection.execute("DELETE FROM fmus where id < #{MAX_ID}")

      ActiveRecord::Base.connection.execute("DELETE FROM user_permissions where id < #{MAX_ID}")
      ActiveRecord::Base.connection.execute("DELETE FROM api_keys where id < #{MAX_ID}")
      ActiveRecord::Base.connection.execute("DELETE FROM users where id < #{MAX_ID}")

      # Removes the operators that are not needed (don't belong to the countries selected)
      ActiveRecord::Base.connection.execute("DELETE FROM operators where country_id not in #{country_ids}")
      ActiveRecord::Base.connection.execute("DELETE FROM operator_translations where operator_id not in (SELECT id from operators)")
      # Updates the ids of the operators that are smaller than MAX_ID
      ActiveRecord::Base.connection.execute("UPDATE operators set id = (id + #{MAX_ID + MIN_ID}) where id < #{MAX_ID}")
      ActiveRecord::Base.connection.execute("UPDATE operator_translations set operator_id = (operator_id + #{MAX_ID + MIN_ID}) where operator_id < #{MAX_ID}")
      ActiveRecord::Base.connection.execute("UPDATE operator_documents set operator_id = (operator_id + #{MAX_ID + MIN_ID}) where operator_id < #{MAX_ID}")
      ActiveRecord::Base.connection.execute("UPDATE fmu_operators set operator_id = (operator_id + #{MAX_ID + MIN_ID}) where operator_id < #{MAX_ID}")

      # Updates the operator translations id not to collide
      ActiveRecord::Base.connection.execute("UPDATE operator_translations set id = (id + #{MAX_ID + MIN_ID}) where id < #{MAX_ID}")


      ActiveRecord::Base.connection.execute("SET session_replication_role = 'origin'")

    end

    # Create pg_dump
    puts "Creating dump"
    sh "pg_dump --data-only -U postgres -d fti_api_production_secondary -Fc -t public.operators -t public.operator_translations -t public.fmus -t public.fmu_translations -t public.required_operator_documents -t public.required_operator_document_translations -t public.fmu_operators -t public.operator_documents -t public.operator_document_annexes -t public.users -t public.api_keys -t public.user_permissions --file fti_api_production_secondary.dump"
  end

  desc 'Imports a file into production'
  task import: :environment do |_task, args|
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Logger.new STDOUT
    MAX_ID = 100_000
    country_ids = "(188, 53)"

    return unless Rails.env.production?

    file = 'fti_api_production_secondary.dump'

    # Restore database
    sh "pg_restore -v -d fti_api_production #{file}"

    ActiveRecord::Base.transaction do

      operators_to_remove = []
      # Moves the observations to the imported operator
      Operator.where("country_id in #{country_ids} and id < #{MAX_ID}").find_each do |operator|
        operator.all_observations.find_each do |obs|
          next if obs.fmu_id # This shouldn't happen

          new_operator = Operator.with_translations.where(name: operator.name).order(:id).last
          next if new_operator.id == operator.id

          obs.update_columns(operator_id: new_operator.id)
          operators_to_remove << operator.id
        end
      end

      operators_to_remove.uniq!

      # Remove deleted operators
      operators_to_remove.each do |operator_id|
        Operator.find(operator_id).destroy!
      end


      # Remove duplicated operators
      Operator.where("country_id in #{country_ids} and id < #{MAX_ID}").find_each do |operator|
        next if ObservationOperator.where(operator_id: operator.id).any?
        operator.destroy!
      end


      # Create the documents for operators
      Operator.where("country_id in #{country_ids}").find_each do |operator|
        operator.rebuild_documents
      end


      puts "finished"
    end
  end
end
