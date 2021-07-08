# == Schema Information
#
# Table name: document_files
#
#  id         :integer          not null, primary key
#  attachment :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe DocumentFile, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
