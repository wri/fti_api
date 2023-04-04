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

require "rails_helper"

RSpec.describe Comment, type: :model do
  subject(:comment) { FactoryBot.build(:comment) }

  it "is valid with valid attributes" do
    expect(comment).to be_valid
  end

  describe "Class methods" do
    describe "#build" do
      context "when commentable, user and body are present" do
        it "build(a new Comment with the specified data" do
          user = create(:user)
          observation = create(:observation)
          comment = Comment.build({
            "commentable_type" => "Observation",
            "commentable_id" => observation.id,
            "user" => user,
            "body" => "body"
          })

          expect(comment.commentable).to eql observation
          expect(comment.user_id).to eql user.id
          expect(comment.body).to eql "body"
        end
      end
    end
  end
end
