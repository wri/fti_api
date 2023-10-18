class UserObserver < ApplicationRecord
  belongs_to :user
  belongs_to :observer
end
