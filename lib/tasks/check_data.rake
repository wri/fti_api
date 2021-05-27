namespace :check do
  task operator_approved: :environment do
    Operator.find_each do |operator|
      valid_approved_status = operator.operator_documents.signature.approved.any?

      next if valid_approved_status == operator.approved?

      puts "BAD DATA for operator #{operator.id} - #{operator.name} - approved should be #{valid_approved_status} but is #{operator.approved?}"
    end
  end
end
