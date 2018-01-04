# frozen_string_literal: true

require 'active_support/concern'

module Translatable
  extend ActiveSupport::Concern

  # TODO: Try to optimize it
  included do
    after_save :translate

    def translate
      translated_attribute_names.each do |attr|
        translation = translated_attribute_by_locale(attr)
        if translation.any?
          first_translation = translation.first.second
          (I18n.available_locales - [I18n.locale]).each do |locale|
            if translation[locale].blank?
              self.attributes = { attr => first_translation, locale: locale }
              save
            end
          end
        end
      end
    end
  end
end
