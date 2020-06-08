# frozen_string_literal: true

# == Schema Information
#
# Table name: contributors
#
#  id             :integer          not null, primary key
#  website        :string
#  logo           :string
#  priority       :integer
#  category       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  type           :string           default("Partner")
#  contributor_id :integer          not null
#  name           :string           not null
#  description    :text
#

class Partner < Contributor
end
