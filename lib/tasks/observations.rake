namespace :observations do
  desc "Hide observations older than 5 year"
  task hide: :environment do
    Observation.to_be_hidden.update_all(hidden: true, is_active: false, updated_at: DateTime.now)
  end

  desc "Recalculate observation scores for operators"
  task recalculate_scores: :environment do
    operators = Operator.where(id: ScoreOperatorObservation.distinct.select(:operator_id))
    operators.each do |op|
      ScoreOperatorObservation.recalculate!(op)
    end
  end

  task recreate_history: :environment do
    ActiveRecord::Base.transaction do
      ObservationHistory.delete_all

      total_obs = Observation.count
      index = 1
      puts "Total observations: #{total_obs}"
      Observation.unscoped.find_each do |observation|
        puts "Recreating history for observation #{index} with id: #{observation.id}"
        observation.versions.each do |version|
          o = version.reify
          next if o.nil?

          if o.operator_id.present? && Operator.unscoped.where(id: o.operator_id).count.zero?
            puts "operator #{o.operator_id} does not exist, skipping"
            next
          end

          o.create_history
        end
        observation.create_history
        index += 1
      end
    end
  end

  desc "Task that will rename existing evidence document files"
  task rename_evidence_files: :environment do
    ObservationDocument.find_each do |od|
      next unless od.attachment?

      od.attachment.recreate_versions!
      od.save!
      puts "Evidence document #{od.id} new filename #{od.attachment.filename}"
    end
  end

  desc "Finds obs with swapped coords and fixing them"
  task fix_swapped_coords: :environment do
    for_real = ENV["FOR_REAL"] == "true"

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real

    query = <<~SQL
      select temp2.* from
      (
        select
          temp.id,
          temp.operator_id,
          temp.operator_name,
          ST_DISTANCE(pointSwapped, centroid) < ST_DISTANCE(point, centroid) as swapped_closer_to_centroid
        from
        (
          select o.*, o.name as operator_name, f.geometry, ST_CENTROID(f.geometry) as centroid,
            ST_SetSRID(ST_POINT(o.lng, o.lat), 4326) as point,
            ST_SetSRID(ST_POINT(o.lat, o.lng), 4326) as pointSwapped
          from
            observations o
          inner join fmus f on f.id = o.fmu_id
          where f.geojson is not null
        ) as temp
      ) as temp2
      where swapped_closer_to_centroid = true
    SQL

    results = ActiveRecord::Base.connection.execute(query).to_a
    puts "#{results.count} results with swapped lng lat inside fmu"
    puts "Observation ids: #{results.pluck("id").join(", ")}"
    ActiveRecord::Base.transaction do
      Observation.skip_callback(:save, :after, :update_fmu_geojson)
      results.each do |res|
        observation = Observation.find(res["id"])
        lng = observation.lat
        lat = observation.lng
        puts "Updating lng/lat for observation #{observation.id}"
        observation.update!(lng: lng, lat: lat)
      end
      Observation.set_callback(:save, :after, :update_fmu_geojson)

      raise ActiveRecord::Rollback unless for_real
    end
    puts "Done :)"
  end

  desc "Reject invalid observations that don't meet validation requirements"
  task reject_invalid_observations: :environment do
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN MODE - No changes will be made"
    puts "=" * 80

    # Find a system user to use as reviewer for QualityControl records
    system_user = User.find_by(email: ENV["RESPONSIBLE_EMAIL"]&.downcase)

    if system_user.nil?
      puts "ERROR: No user found to use as reviewer. Cannot proceed."
      exit 1
    end

    puts "Using user #{system_user.email} as reviewer for QualityControl records"
    puts

    observations_to_check = Observation.where.not(validation_status: ["Created", "Rejected"])

    total_checked = 0
    invalid_count = 0
    error_count = 0

    users_getting_emails = {}

    # Skip QualityControl callback to prevent automatic status update
    # We'll update the status manually after creating the QC record
    QualityControl.skip_callback(:create, :after, :update_reviewable_qc_status) if for_real

    begin
      observations_to_check.find_each do |observation|
        total_checked += 1

        # Check if observation is valid
        next if observation.valid?

        invalid_count += 1

        # Get observer's locale for error messages
        # Use first observer's first user's locale, or default locale
        observer_user = observation.observers.first&.users&.first
        observer_locale = observer_user&.locale || I18n.default_locale

        error_message = I18n.with_locale(observer_locale) do
          observation.errors.full_messages.join("; ")
        end
        if observer_locale != "en"
          error_message += " (EN: #{I18n.with_locale(:en) { observation.errors.full_messages.join("; ") }})"
        end
        if observer_locale != "fr"
          error_message += " (FR: #{I18n.with_locale(:fr) { observation.errors.full_messages.join("; ") }})"
        end

        skip_email_notification = false

        if observation.validation_status != "Needs revision"
          User.where(id: observation.observers.joins(:users).distinct.pluck("users.id")).pluck(:email).uniq.each do |email|
            users_getting_emails[email] ||= 0
            users_getting_emails[email] += 1
          end
        else
          # if observation already marked as Needs revision, append last QC comment to provide more context
          last_qc_message = observation.latest_quality_control&.comment
          error_message = "#{last_qc_message} \n #{error_message}" if last_qc_message.present?
          skip_email_notification = true
        end

        puts "Observation ##{observation.id} (status: #{observation.validation_status}) is invalid:"
        puts "  Observer locale: #{observer_locale}"
        puts "  Message: #{error_message}"


        if for_real
          ActiveRecord::Base.transaction do
            Observation.skip_callback(:commit, :after, :notify_about_changes) if skip_email_notification

            qc = QualityControl.create!(
              reviewable: observation,
              reviewer: system_user,
              passed: false,
              comment: error_message
            )
            observation.update!(validation_status: "Rejected")

            puts "  ✓ Created QualityControl ##{qc.id} and rejected observation"
          rescue => e
            error_count += 1
            puts "  ✗ Error: #{e.message}"
            puts "    #{e.backtrace.first}" if ENV["DEBUG"]
          ensure
            Observation.set_callback(:commit, :after, :notify_about_changes) if skip_email_notification
          end
        end

        puts
      end
    ensure
      # Re-enable callback
      QualityControl.set_callback(:create, :after, :update_reviewable_qc_status) if for_real
    end

    puts users_getting_emails.empty? ? "No users to notify." : "Users to be notified:"
    users_getting_emails.each do |email, count|
      puts "  #{email}: #{count} emails sent"
    end

    puts "=" * 80
    puts "Summary:"
    puts "  Total observations checked: #{total_checked}"
    puts "  Invalid observations found: #{invalid_count}"
    puts "  Successfully rejected: #{invalid_count - error_count}" if for_real
    puts "  Errors encountered: #{error_count}" if error_count > 0 && for_real
  end
end
