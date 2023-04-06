namespace :observations_report do
  desc "Updates the file names"
  task update_file: :environment do
    Rails.logger.warn ":::Going to update the file names:::"
    ObservationReport.find_each do |report|
      next unless report.attachment?

      report.attachment.recreate_versions!
      report.save!
      Rails.logger.warn "Report #{report.id} now has filename #{report.attachment.filename}"
    end
    Rails.logger.warn ":::Finished updating file names:::"
  end
end
