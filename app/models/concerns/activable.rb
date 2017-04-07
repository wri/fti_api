# frozen_string_literal: true

module Activable
  extend ActiveSupport::Concern

  included do
    before_save :set_deactivated_at

    scope :filter_actives,   -> { where(is_active: true)  }
    scope :filter_inactives, -> { where(is_active: false) }

    def activate
      update! is_active: true
    end

    def deactivate
      update! is_active: false
    end

    def deactivated?
      !self.is_active?
    end

    def activated?
      self.is_active?
    end

    def set_deactivated_at
      self.deactivated_at = Time.now if attributes.key?('deactivated_at') && self.is_active_changed? && self.deactivated?
    end

    def status
      self.is_active? ? 'activated' : 'deactivated'
    end
  end

  class_methods do
  end
end
