# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  commentable_id   :integer
#  commentable_type :string
#  body             :text
#  user_id          :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryBot.define do
  factory :comment do
    sequence(:body) { |n| "CommentBody#{n}" }

    after(:build) do |random_comment|
      random_comment.user ||= FactoryBot.create :user
      random_comment.commentable ||=
        FactoryBot.create :observation
    end
  end
end
