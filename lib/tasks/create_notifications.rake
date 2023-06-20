namespace :scheduler do
  desc "creates the notifications daily"
  task create_notifications: :environment do
    group_ids = []
    NotificationGroup.order(days: :asc).each do |notification_group|
      group_ids << notification_group.id
      notification_date = Time.zone.today + notification_group.days
      OperatorDocument.includes(operator: :users).find_by_sql(sql(notification_date, group_ids.join(", "))).each do |od|
        od.operator.users.each do |user|
          Notification.create!(notification_group: notification_group, operator_document: od, user: user)
        end
      end
    end
  end

  def sql(date, group_ids)
    # TODO: This would be better in ARel
    <<~SQL
      select distinct
      	operator_documents.*
      from
      	operator_documents
      inner join required_operator_documents on
      	required_operator_documents.id = operator_documents.required_operator_document_id
      left outer join notifications on
      	notifications.operator_document_id = operator_documents.id and notifications.notification_group_id in (#{group_ids}) and notifications.solved_at is null
      where
      	operator_documents.deleted_at is null
      	and (expire_date < '#{date}'::date
      		and status = #{OperatorDocument.statuses[:doc_valid]}
      		and required_operator_documents.contract_signature = false)
      	and notifications.id is null
    SQL
  end
end
