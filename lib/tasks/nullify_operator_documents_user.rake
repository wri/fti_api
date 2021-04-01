namespace :operator_documents do
  desc 'Nullify operator documents user_id if user does not exists'
  task nullify: :environment do

    # od_wit_nil_user = OperatorDocument.with_deleted.all.select{ |od| od if od.user == nil and od.user_id != nil }
    # puts od_wit_nil_user.count
    # puts 'Going to nullify #{od_wit_nil_user.count} operator documents user_id because user does not exists'

    OperatorDocument.with_deleted.all.each do |od|
      od.update_columns(user_id: nil) if od.user == nil
    end

    # od_wit_nil_user_after = OperatorDocument.with_deleted.all.select{ |od| od if od.user == nil and od.user_id != nil }
    # puts od_wit_nil_user_after.count
    # puts 'To nullify #{od_wit_nil_user_after.count} after the great nullification'
  end
end