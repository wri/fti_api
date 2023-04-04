namespace :operator_ids do
  desc "Creates the new operator id"
  task create: :environment do
    puts "Going to update the operator_ids"
    operators = Operator.where(operator_id: nil)
    operators.each do |operator|
      if operator.country_id.present?
        operator.update_columns(operator_id: "#{operator.country.iso}-unknown-#{operator.id}")
      else
        operator.update_columns(operator_id: "na-unknown-#{operator.id}")
      end

      puts "... #{operator.operator_id}"
    end
  end
end
