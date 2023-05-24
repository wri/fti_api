namespace :observations do
  desc "Hide observations older than 5 year"
  task hide: :environment do
    Observation.to_be_hidden.update_all(hidden: true, updated_at: DateTime.now)
  end

  desc "Recalculate observation scores for operators"
  task recalculate_scores: :environment do
    operators = Operator.where(id: ScoreOperatorObservation.pluck(:operator_id).uniq)
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

  desc "Set resposible admin by default"
  task set_responsible_admin: :environment do
    Observer.unscoped.find_each do |observer|
      puts "Setting responsible admin by default for observer with id: #{observer.id}"
      observer.set_responsible_admin
      observer.save!
    end

    Observation.unscoped.find_each do |observation|
      puts "Setting responsible admin by default for observation with id: #{observation.id}"
      observation.set_default_responsible_admin
      puts observation.responsible_admin_id
      observation.save!
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
    puts "Observation ids: #{results.map { |r| r["id"] }.join(", ")}"
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
end
