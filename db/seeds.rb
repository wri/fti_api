# sh "bin/rails db:fixtures:load FIXTURES_PATH=db/fixtures"
require "active_record/fixtures"

fixtures_dir = File.join(Rails.root, "db", "fixtures")
fixture_files = Dir["#{fixtures_dir}/**/*.yml"].map { |f| f[(fixtures_dir.size + 1)..-5] }

# NOTE: in case of integrity errors, check config/initializers/active_record_fixtures.rb for monkey patch to get better error messages
# TODO: remove monkey patch when upgrading to Rails 7.1
ActiveRecord::FixtureSet.create_fixtures(fixtures_dir, fixture_files)

unless User.find_by(email: "admin@example.com")
  user = User.new(email: "admin@example.com", password: "password", password_confirmation: "password", name: "Admin")
  user.build_user_permission(user_role: "admin")
  user.save!
end

unless User.find_by(email: "user@example.com")
  user = User.new(email: "user@example.com", password: "password", password_confirmation: "password", name: "User", is_active: true)
  user.build_user_permission(user_role: "user")
  user.save!
end

unless User.find_by(email: "webuser@example.com")
  user = User.new(email: "webuser@example.com", password: "password", password_confirmation: "password", name: "Web", is_active: true)
  user.build_user_permission(user_role: "user")
  user.save!
end

Rake::Task["sync:ranking"].invoke
Operator.find_each { |o| ScoreOperatorDocument.recalculate!(o) }
