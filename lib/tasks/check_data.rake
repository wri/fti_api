namespace :check do
  task operator_approved: :environment do
    Operator.find_each do |operator|
      next unless operator.operator_documents.signature.any?

      valid_approved_status = operator.operator_documents.signature.approved.any?

      next if valid_approved_status == operator.approved?

      active_or_not = operator.is_active? ? 'ACTIVE' : 'NOT_ACTIVE'

      puts "BAD DATA for #{active_or_not} , FA: #{operator.fa_id.present?} operator #{operator.id} - #{operator.name} - approved should be #{valid_approved_status} but is #{operator.approved?}"
    end
  end
end
