# frozen_string_literal: true

# copy paste from https://github.com/CristiRazvi/enum_attributes_validation/blob/master/lib/enum_attributes_validation.rb
# just removed default message, could do a fork but the gem is really small so easy to include
module EnumAttributesValidation
  extend ActiveSupport::Concern

  included do
    attr_writer :enum_invalid_attributes
    def enum_invalid_attributes
      @enum_invalid_attributes ||= {}
    end
    validate :check_enum_invalid_attributes

    private

    def check_enum_invalid_attributes
      if enum_invalid_attributes.present?
        enum_invalid_attributes.each do |key, opts|
          if opts[:message]
            errors.add(:base, opts[:message])
          else
            errors.add(key, :invalid_enum, value: opts[:value], valid_values: self.class.send(key.to_s.pluralize).keys.sort.join(", "))
          end
        end
      end
    end
  end

  class_methods do
    def validate_enum_attributes(*attributes, **opts)
      attributes.each do |attribute|
        string_attribute = attribute.to_s

        define_method "#{string_attribute}=" do |argument|
          if argument.present?
            string_argument = argument.to_s
            self[string_attribute] = string_argument if self.class.send(string_attribute.pluralize).key?(string_argument)
            enum_invalid_attributes[attribute] = opts.merge(value: string_argument) unless self.class.send(string_attribute.pluralize).key?(string_argument)
          end
        end
      end
    end

    def validate_enum_attribute(*attributes)
      validate_enum_attributes(*attributes)
    end
  end
end

# include the extension in active record
ActiveSupport.on_load(:active_record) { include EnumAttributesValidation }
