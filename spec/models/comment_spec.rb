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

  let!(:annex_options) {
    options = {}
    options['commentable_type'] = @annex.class.name
    options['commentable_id']   = @annex.id
    options['body']             = @body
    options['user']             = @user
    options
  }

  let!(:observation_options) {
    options = {}
    options['commentable_type'] = @observation.class.name
    options['commentable_id']   = @observation.id
    options['body']             = @body
    options['user']             = @user
    options
  }

  it 'Comment on annex' do
    @comment = Comment.build(annex_options)
    @comment.save!
    expect(@comment.valid?).to             eq(true)
    expect(@comment.commentable_type).to   eq('AnnexOperator')
    expect(@annex.reload.comments.size).to eq(1)
  end

  it 'Comment on observation' do
    @comment = Comment.build(observation_options)
    @comment.save!
    expect(@comment.valid?).to                   eq(true)
    expect(@comment.commentable_type).to         eq('Observation')
    expect(@observation.reload.comments.size).to eq(1)
  end
end
