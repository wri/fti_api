# frozen_string_literal: true

module FileDataImporter
  class BelongsToAssociation
    attre_accessor :class_name, :permited_attributes, :permited_translations

    def initialize(class_name, permited_attributes = [], permited_translations = [])
      @class_name = class_name
      @permited_attributes = permited_attributes
      @permited_translations = permited_translations
    end
  end
end
