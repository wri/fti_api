# frozen_string_literal: true

module ActiveAdmin
  module Translations
    module TranslatedRowExtension
      def translated_row(attribute, options = {}, &block)
        record = @resource_instance || @collection.first
        raise "translated_row can only by used in resources that support translations" unless record.respond_to?(:translations)

        translations = record.translations.index_by(&:locale)
        available_locales = (options[:locales] || I18n.available_locales).map(&:to_sym)

        row attribute do |resource|
          div class: "translated-attribute", data: {attribute: attribute} do
            available_locales.each do |locale|
              translation = translations[locale]
              translated_from = translation.send("#{attribute}_translated_from") if translation.respond_to?("#{attribute}_translated_from")
              value = if block_given?
                I18n.with_locale(locale) do
                  yield resource
                end
              else
                translation&.send(attribute)
              end

              div class: "translation-content", data: {locale: locale}, style: ((locale == I18n.locale) ? "" : "display: none;") do
                if value.present?
                  text_node value
                  if translated_from.present?
                    br
                    text_node I18n.t("active_admin.shared.auto_translated_from", translated_from: translated_from)
                  end
                else
                  span(class: "empty") { I18n.t("active_admin.empty") }
                end
              end
            end

            div class: "translation-links" do
              available_locales.each_with_index do |locale, index|
                span class: "translation-link #{"active" if locale == I18n.locale}", data: {locale: locale} do
                  locale.upcase
                end
                text_node " " unless index == available_locales.length - 1
              end
            end
          end
        end
      end
    end
  end
end
