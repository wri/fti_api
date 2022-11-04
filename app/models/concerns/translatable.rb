# frozen_string_literal: true

require 'active_support/concern'

module Translatable
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_translate
    after_save :translate
    skip_callback :save, :after, :translate, if: :skip_translate

    def translate
      translated_attribute_names.each do |attr|
        translation = translated_attribute_by_locale(attr)
        if translation.any?
          first_translation = translation.first.second
          (I18n.available_locales - [I18n.locale]).each do |locale|
            if translation[locale].blank? && first_translation.present?
              # assign_attributes
              self.attributes = { attr => first_translation, locale: locale }
            end
          end
        end
      end
      self.skip_translate = true
      self.save
    end
  end
end
