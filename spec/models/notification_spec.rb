# == Schema Information
#
# Table name: notifications
#
#  id                    :integer          not null, primary key
#  last_displayed_at     :datetime
#  dismissed_at          :datetime
#  solved_at             :datetime
#  operator_document_id  :integer          not null
#  user_id               :integer          not null
#  notification_group_id :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require 'rails_helper'

RSpec.describe Notification, type: :model do

end
