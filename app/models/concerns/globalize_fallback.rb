# frozen_string_literal: true

require 'active_support/concern'

module GlobalizeFallback
  extend ActiveSupport::Concern

  # TODO: Try to optimize it
  included do
    scope :with_fallback_translations, -> {
      joins(:translations)
          .joins("INNER JOIN (
               SELECT #{fk_column},
                 CASE
                   WHEN MAX(CASE
                              WHEN locale = '#{Globalize.fallbacks[0]}' then 1 -- default language
                              WHEN locale = '#{Globalize.fallbacks[1]}' then 0 -- fallback
                            END) = 1
                   THEN '#{Globalize.fallbacks[0]}'
                   ELSE '#{Globalize.fallbacks[1]}'
                 END as pref_loc
               FROM #{self.translations_table_name}
              GROUP BY #{fk_column} ) pref ON pref.#{fk_column}= #{translations_table_name}.#{fk_column}
                                          AND pref.pref_loc = #{translations_table_name}.locale")
    }

    def self.fk_column
      self.to_s.downcase + '_id'
    end

    def self.coalesce_string
      translated_fields = self.translation_class.attribute_types.keys - ['id', 'locale', 'created_at', 'updated_at', "#{fk_column}"]
      coalesce_array = []
      translated_fields.each do |t|
        coalesce_array << "COALESCE(original.#{t}, fallback.#{t}) as #{t}_2"
      end
      coalesce_array.join(', ')
    end
  end

  class_methods do
  end
end
