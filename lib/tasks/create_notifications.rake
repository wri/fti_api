namespace :notifications do
  desc 'creates the notifications daily'
  task create: :environment do
    group_ids = []
    NotificationGroup.order(days: :asc).each do |notification_group|
      group_ids << notification_group.id
      OperatorDocument.to_expire(Date.today + notification_group.days)
                      .without_notification_groups(group_ids).each do |od|
        od.operator.users.each do |user|
          Notification.create!(notification_group: notification_group, operator_document: od, user: user)
        end
      end
    end
  end
end


