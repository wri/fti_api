FactoryGirl.define do
  factory :comment do
    sequence(:body) { |n| "CommentBody#{n}" }

    after(:build) do |random_comment|
      random_comment.user ||= FactoryGirl.create :user
      random_comment.commentable ||=
        FactoryGirl.create :observation
    end
  end
end
