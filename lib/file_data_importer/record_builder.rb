# frozen_string_literal: true

module FileDataImporter
  class RecordBuilder
    attr_accessor :class_name, :permited_attributes, :permited_translations
    attr_reader :belongs_to_associations

    def initialize(class_name = nil, permited_attributes = [], permited_translations = [])
      @class_name = class_name
      @permited_attributes = permited_attributes
      @permited_translations = permited_translations
      @belongs_to_associations = []
    end

    def belongs_to(class_name, permited_attributes = [], permited_translations = [])
      association = BelongsToAssociation.new(class_name, permited_attributes, permited_translations)
      belongs_to_associations.push(association)
    end

    def save(attributes = {})
      # returns { status: saved/errored, attributes/errors: {}/[] }
    end

    # def build(attributes = {})
    #   attributes = extract_attributes(attributes)
    #   class_name.new(attributes)
    # end

    private

    def extract_attributes(attributes)
      attributes.slice(*permited_attributes).compact
    end
  end
end
