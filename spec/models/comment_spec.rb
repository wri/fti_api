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

require 'rails_helper'

RSpec.describe Comment, type: :model do
  before :each do
    @user        = create(:admin)
    @observation = create(:observation_1)
    @annex       = @observation.severity.annex_operator
    @severity    = @observation.severity
    @body        = 'Lorem ipsum dolor..'
  end

  it 'Comment on annex' do
    @comment = Comment.build(@annex, @user, @body)
    @comment.save!
    expect(@comment.valid?).to           eq(true)
    expect(@comment.commentable_type).to eq('AnnexOperator')
    expect(@annex.comments.size).to      eq(1)
  end

  it 'Comment on observation' do
    @comment = Comment.build(@observation, @user, @body)
    @comment.save!
    expect(@comment.valid?).to            eq(true)
    expect(@comment.commentable_type).to  eq('Observation')
    expect(@observation.comments.size).to eq(1)
  end

  it 'Comment on severity and count user comments' do
    @comment = Comment.build(@severity, @user, @body)
    @comment.save!
    expect(@comment.valid?).to           eq(true)
    expect(@comment.commentable_type).to eq('Severity')
    expect(@severity.comments.size).to   eq(1)
    expect(@user.comments.size).to       eq(1)
  end
end
