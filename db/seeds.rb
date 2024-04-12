# # sh "bin/rails db:fixtures:load FIXTURES_PATH=db/fixtures"
require "active_record/fixtures"

fixtures_dir = File.join(Rails.root, "db", "fixtures")
fixture_files = Dir["#{fixtures_dir}/**/*.yml"].pluck((fixtures_dir.size + 1)..-5)

$stdout.puts "Loading fixtures..."
# NOTE: in case of integrity errors, check config/initializers/active_record_fixtures.rb for monkey patch to get better error messages
# TODO: remove monkey patch when upgrading to Rails 7.1
ActiveRecord::FixtureSet.create_fixtures(fixtures_dir, fixture_files)

$stdout.puts "Creating test users..."

common_fields = {password: "password", password_confirmation: "password", locale: :en}
admin = User.create_with(**common_fields, name: "Admin").find_or_create_by!(email: "admin@example.com") do |user|
  user.build_user_permission(user_role: "admin")
end
User.create_with(**common_fields, name: "User").find_or_create_by(email: "user@example.com") do |user|
  user.build_user_permission(user_role: "user")
end
api_user = User.create_with(**common_fields, name: "Web").find_or_create_by(email: "webuser@example.com") do |user|
  user.build_user_permission(user_role: "user")
end
api_user.regenerate_api_key
holding = User.create_with(**common_fields, name: "Holding").find_or_create_by(email: "holding@example.com") do |user|
  user.build_user_permission(user_role: "holding")
end
operator = User.create_with(**common_fields, name: "Operator").find_or_create_by(email: "operator@example.com") do |user|
  user.build_user_permission(user_role: "operator")
end
government = User.create_with(**common_fields, name: "Government").find_or_create_by(email: "gov@example.com") do |user|
  user.build_user_permission(user_role: "government")
end
ngo = User.create_with(**common_fields, name: "NGO").find_or_create_by(email: "ngo@example.com") do |user|
  user.build_user_permission(user_role: "ngo")
end
ngo_manager = User.create_with(**common_fields, name: "NGO Manager").find_or_create_by(email: "ngo_manager@example.com") do |user|
  user.build_user_permission(user_role: "ngo_manager")
end

$stdout.puts "Connecting users with test data..."

cameroon = Country.find_by!(name: "Cameroon")
congo = Country.find_by!(name: "Congo")
ifo = Operator.find_by!(slug: "ifo-interholco")
ogf = Observer.find_by!(name: "OGF")
ocean = Observer.find_by!(name: "OCEAN")
foder = Observer.find_by!(name: "FODER")

holding.update!(holding: Holding.first)
operator.update!(operator: ifo)
ngo.update!(observer: ogf)
ngo_manager.update!(observer: ogf, managed_observers: [ocean, foder])
government.update!(country: cameroon)
admin.update!(responsible_for_countries: [cameroon, congo])

# Observer.find_each { |o| o.update!(responsible_admin: admin) }
OperatorDocumentAnnex.find_each { |a| a.update!(user: operator) }

$stdout.puts "Syncing test data..."

sample_file_base64 = "data:application/pdf;base64,#{Base64.encode64(File.read(File.join(Rails.root, "spec", "support", "files", "doc.pdf")))}"

# observation report has validation on attachment, so to not fail some e2e specs make sure all reports has some attachments
ObservationReport.find_each do |report|
  if report.attachment.blank?
    report.remove_attachment!
    report.skip_observers_sync = true
    report.save!(validate: false)
    report.update!(attachment: sample_file_base64)
  end
end
Fmu.find_each(&:update_geometry)
Rake::Task["sync:ranking"].invoke
Operator.find_each { |o| ScoreOperatorDocument.recalculate!(o) }
