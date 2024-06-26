namespace :users do
  task import_names: :environment do
    abort "Please provide a file name with the FILE environment variable" unless ENV["FILE"]
    file_name = ENV["FILE"]

    strip_converter = ->(field) { field&.strip }
    user_names = CSV.parse(
      File.read(file_name),
      headers: true,
      converters: [strip_converter],
      header_converters: :symbol
    )
    user_names.each do |user_name|
      user = User.find_by(id: user_name[:id])
      next unless user

      user.update!(
        first_name: user_name[:first_name],
        last_name: user_name[:last_name]
      )
    end
  end
end
