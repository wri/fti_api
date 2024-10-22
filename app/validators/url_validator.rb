class UrlValidator < ActiveModel::EachValidator
  VALID_SCHEMES = %w[http https].freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    uri = URI.parse(value)

    record.errors.add(attribute, :url_valid_scheme) unless VALID_SCHEMES.include?(uri.scheme)
    record.errors.add(attribute, :invalid) if uri.host.blank?
  rescue URI::InvalidURIError
    record.errors.add(attribute, :invalid)
  end
end
