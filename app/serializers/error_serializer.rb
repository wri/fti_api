# frozen_string_literal: true

module ErrorSerializer
  def self.serialize(errors, status)
    return if errors.nil?

    json_error = { 'errors': [] }

    errors.messages.each do |err_type, messages|
      messages.each do |msg|
        json_error[:errors] << { 'status': status, 'title': "#{err_type} #{msg}" }
      end
    end
    json_error
  end
end
