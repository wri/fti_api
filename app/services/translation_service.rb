# Service that communicates with the Google Translator API
class TranslationService
  def initialize
    @translator = Google::Cloud::Translate.translation_v2_service(
      key: ENV["GOOGLE_API_KEY"]
    )
  end

  def call(text, from, to)
    translation = @translator.translate text, from: from, to: to

    translation.text
  end
end
