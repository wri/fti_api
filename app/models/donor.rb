# frozen_string_literal: true
# == Schema Information
#
# Table name: contributors
#
#  id         :integer          not null, primary key
#  website    :string
#  logo       :string
#  priority   :integer
#  category   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string           default("Partner")
#

class Donor < Contributor

end
