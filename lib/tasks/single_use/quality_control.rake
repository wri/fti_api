namespace :quality_control do
  desc "Quality control backfill based on paper trail history"
  task backfill: :environment do
    QualityControl.skip_callback(:create, :after, :update_reviewable_qc_status)
    QualityControl.skip_callback(:save, :before, :set_metadata)

    QualityControl.delete_all if ENV["DELETE_EXISTING_QC"]

    # User with id 1 was first generic admin user, a lot of obervations have a history that was created by this user
    # let's add this user back to db
    secure_password = SecureRandom.hex(20)
    unless User.exists?(id: 1)
      User.create!(
        id: 1, email: "admin@example.com", is_active: false,
        first_name: "Admin", last_name: "User",
        password: secure_password, password_confirmation: secure_password,
        user_permission: UserPermission.new(user_role: "admin")
      )
    end

    Observation.unscoped.includes(:versions).find_each do |observation|
      observation.versions.each do |version|
        next unless version.event == "update"
        next unless version.changeset.key?("validation_status")
        next unless ["Needs revision", "Ready for publication"].include?(version.changeset["validation_status"].last)

        reviewer = User.where(id: version.whodunnit).first
        if reviewer.nil?
          puts "No user found with id: #{version.whodunnit}"
          next
        end

        puts "Creating QC for observation #{observation.id}: version #{version.id}, created at: #{version.created_at}, whodunnit: #{version.whodunnit}"

        passed = version.changeset["validation_status"].last == "Ready for publication"
        comment = version.reify.admin_comment

        # check if that qc already not exists as paper trail history is very weird and sometimes it creates multiple
        # similar version changes in a very short time (miliseconds apart mostly)
        duplicate_time_range = (version.created_at - 1.minute)..(version.created_at + 1.minute)
        any_duplicates = QualityControl
          .where(reviewer: reviewer, reviewable: observation, passed: passed, comment: comment)
          .exists?(created_at: duplicate_time_range)
        if any_duplicates
          puts "Duplicate quality control found, skipping"
          next
        end

        qc = QualityControl.new(
          reviewer: reviewer,
          reviewable: observation,
          passed: passed,
          comment: comment,
          created_at: version.created_at,
          updated_at: version.created_at,
          metadata: {
            level: "QC2",
            decision: version.changeset["validation_status"].last,
            backfilled: true
          }
        )
        qc.save(validate: false)
      end
    end

    puts "Checking if all observations that needs revision have a quality control..."
    Observation.where(validation_status: "Needs revision").where.missing(:quality_controls).find_each do |observation|
      puts "Observation with id: #{observation.id} does not have a quality control"
    end
    puts "Checking if all observations that are ready for publication have a quality control..."
    Observation.where(validation_status: "Ready for publication").where.missing(:quality_controls).find_each do |observation|
      puts "Observation with id: #{observation.id} does not have a quality control"
    end

    QualityControl.set_callback(:create, :after, :update_reviewable_qc_status)
    QualityControl.set_callback(:save, :before, :set_metadata)
  end
end