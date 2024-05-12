class TranslationJob < ApplicationJob
  class TranslationException < StandardError
  end

  queue_as :default
  retry_on TranslationException, wait: 5.minutes, attempts: 3

  # Takes an entity (an ActiveRecord object) and an original_locale, and translates all the fields based on that locale
  # The model should have a TRANSLATABLE_FIELDS constant
  def perform(entity, original_locale)
    return unless entity.class.const_defined?(:AUTOMATICALLY_TRANSLATABLE_FIELDS)

    fields = entity.class.const_get(:AUTOMATICALLY_TRANSLATABLE_FIELDS)
    translation_service = TranslationService.new
    translated_fields = {}

    fields.each do |field|
      translated_fields[field] = {}
      I18n.available_locales.each do |locale|
        next if locale == original_locale.to_sym

        I18n.with_locale original_locale do
          next if entity.send(field).blank?

          translated_fields[field][locale] = translation_service.call(entity.send(field), I18n.locale, locale)
        end
      end
    end

    translated_fields.each do |field, translation|
      translation.each do |locale, text|
        I18n.with_locale locale do
          entity.send("#{field}=", text)
          entity.translation.send("#{field}_translated_from=", original_locale)
        end
      end
    end
    entity.save
  rescue => e
    Sentry.capture_exception(e)
    raise TranslationException
  end
end
