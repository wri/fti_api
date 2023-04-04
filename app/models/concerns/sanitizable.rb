# frozen_string_literal: true

module Sanitizable
  extend ActiveSupport::Concern

  included do
    before_validation :sanitize_web
  end

  protected

  def sanitize_web
    if attributes.key?("web_url")
      unless web_url.blank? || web_url.start_with?("http://") || web_url.start_with?("https://")
        self.web_url = "http://#{web_url}"
      end
    end
  end
end
