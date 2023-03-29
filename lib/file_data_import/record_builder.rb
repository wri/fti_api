# frozen_string_literal: true

module FileDataImport
  class RecordBuilder
    def initialize
      @belongs_to = []
    end

    def belongs_to(class_name, **options)
      @belongs_to.push([class_name, options])
    end

    def record(class_name, **options)
      @class_name = class_name
      @options = options
    end

    def build(raw_attributes = {})
      record = Record.new(@class_name, raw_attributes, **@options)
      @belongs_to.each do |class_name, options|
        record.belongs_to(BelongsToAssociation.new(class_name, raw_attributes, **options))
      end

      record
    end
  end
end
