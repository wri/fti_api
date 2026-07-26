# frozen_string_literal: true

module Activable
  extend ActiveSupport::Concern

  included do
    before_save :set_activation_history

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

  def set_activation_history
    self.deactivated_at = Time.zone.now if attributes.key?("deactivated_at") && is_active_changed? && deactivated?
    self.last_activated_at = Time.zone.now if attributes.key?("last_activated_at") && is_active_changed? && activated?
  end

  def status
    is_active? ? "activated" : "deactivated"
  end

  class_methods do
  end
end
