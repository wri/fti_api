# Service that communicates with the Google Translator API
class TranslationService
  def initialize
    @translator = Google::Cloud::Translate.translation_v2_service(
      key: ENV["GOOGLE_API_KEY"]
    )
  end

  # the API returns line breaks it was not given, so lines are translated separately and the layout rebuilt here
  def call(text, from, to)
    lines = text.to_s.gsub(/\r\n?/, "\n").split("\n", -1)
    translatable = lines.compact_blank
    return text if translatable.empty?

    result = @translator.translate(*translatable, from: from, to: to, format: :text)
    translated = Array.wrap(result).map { |t| t.text.gsub(/\s*\n\s*/, " ").strip }

    lines.map { |line| line.present? ? translated.shift : line }.join("\n")
  end
end
