# frozen_string_literal: true

require "active_support/concern"

module Translatable
  extend ActiveSupport::Concern

  included do
    before_save :copy_translation_to_all_languages
  end

  private

  def copy_translation_to_all_languages
    translated_attribute_names.each do |attr|
      # translated_attribute_by_locale contains all translations but not the fresh ones
      # that is why merging fresh translation with that hash
      translation = translated_attribute_by_locale(attr).merge(I18n.locale.to_s => translated_attributes[attr.to_s])
      if translation.any?
        first_translation = translation.first.second
        (I18n.available_locales - [I18n.locale]).each do |locale|
          if translation[locale].blank? && first_translation.present?
            self.attributes = {attr => first_translation, :locale => locale}
          end
        end
      end
    end
  end
end
