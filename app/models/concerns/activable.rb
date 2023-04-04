# frozen_string_literal: true

module Activable
  extend ActiveSupport::Concern

  included do
    before_save :set_deactivated_at

    scope :filter_actives, -> { where(is_active: true) }
    scope :filter_inactives, -> { where(is_active: false) }
  end

  def activate
    update! is_active: true
  end

  def deactivate
    update! is_active: false
  end

  def deactivated?
    !is_active?
  end

  def activated?
    is_active?
  end

  def set_deactivated_at
    self.deactivated_at = Time.now if attributes.key?("deactivated_at") && is_active_changed? && deactivated?
  end

  def status
    is_active? ? "activated" : "deactivated"
  end

  class_methods do
  end
end
