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
