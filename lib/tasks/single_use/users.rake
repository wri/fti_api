namespace :users do
  desc "Updates users first and last name based on the name"
  task generate_first_last_name: :environment do
    puts "ID, Name, First Name, Last Name"
    User.unscoped.find_each do |user|
      # the name could have multiple words let's assume that first name is normally the first word and the rest is the last name
      # but there could be some exceptions
      # if there are any uppercased words in the name then those will create the last name
      # and the rest will be the first name
      first_name = ""
      last_name = ""
      words = user.name.split
      any_upcased = words.any? { |word| word == word.upcase }
      words.each do |word|
        if any_upcased
          first_name += word + " " if word != word.upcase
          last_name += word + " " if word == word.upcase
        elsif word == words.first
          first_name += word + " "
        else
          last_name += word + " "
        end
      end
      puts "#{user.id}, #{user.name}, #{first_name}, #{last_name}"
    end
  end

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
