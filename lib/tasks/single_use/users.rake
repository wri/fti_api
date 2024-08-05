namespace :users do
  task import_names: :environment do
    abort "Please provide a file name with the FILE environment variable" unless ENV["FILE"]
    file_name = ENV["FILE"]
    invalid_users = ENV["INVALID_USERS"].to_s.split(",").map(&:to_i)

    strip_converter = ->(field) { field&.strip }
    csv = CSV.parse(
      File.read(file_name),
      headers: true,
      converters: [strip_converter],
      header_converters: :symbol
    )
    csv.each do |row|
      user = User.find_by(id: row[:id])
      if user.nil?
        puts "user not found #{row[:id]}"
        next
      end

      organization_account = row[:organization] == "TRUE"
      user.organization_account = organization_account

      if !organization_account
        user.first_name = row[:first_name]
        user.last_name = row[:last_name]
      end

      # skip validation for invalid users
      unless user.save(validate: invalid_users.exclude?(user.id))
        puts "user not saved #{user.id}, active: #{user.is_active} errors: #{user.errors.full_messages}"
      end
    end
  end
end
