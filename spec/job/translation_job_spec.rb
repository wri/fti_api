require "rails_helper"

RSpec.describe TranslationJob, type: :job do
  subject { described_class.new.perform(entity, original_locale) }
  let(:original_locale) { :en }

  context "when entity does not have AUTOMATICALLY_TRANSLATABLE_FIELDS" do
    let(:entity) { create(:operator) }

    it "does not perform translation" do
      expect(TranslationService).not_to receive(:new)
      expect(entity).not_to receive(:save)
      subject
    end
  end

  context "when the entity has AUTOMATICALLY_TRANSLATABLE_FIELDS" do
    context "when the translatable fields are empty" do
      let(:entity) { create(:observation) }

      it "does not perform translation" do
        allow(TranslationService).to receive(:new).and_return(translation_service = instance_double(TranslationService))
        expect(translation_service).not_to receive(:call)
        subject
      end
    end

    context "when the translatable fields are present but not for the original language" do
      let(:entity) { create(:observation) }

      before do
        I18n.with_locale(:fr) do
          entity.details = "details"
          entity.save!
        end
        # When creating a translation, we copy the translation from the existing language to all the others
        # So we need to remove the translation for the original language to simulate this case
        entity.details = nil
        entity.save!
      end

      it "does not perform translation" do
        allow(TranslationService).to receive(:new).and_return(translation_service = instance_double(TranslationService))
        expect(translation_service).not_to receive(:call)
        subject
      end
    end

    context "when there are translatable fields for the original language" do
      let(:entity) { create(:observation, :with_translations) }

      context "when there are needed translations" do
        let(:translation_map) {
          {
            details: {
              fr: "détails",
              es: "detalles",
              pt: "detalhes",
              "zh-CN": "细节",
              ja: "詳細",
              ko: "세부",
              vi: "chi tiết"
            },
            concern_opinion: {
              fr: "préoccupation opinion",
              es: "opinión de preocupación",
              pt: "opinião sobre preocupação",
              "zh-CN": "关注意见",
              ja: "懸念意見",
              ko: "우려되는 의견",
              vi: "ý kiến quan tâm"
            },
            litigation_status: {
              fr: "statut du litige",
              es: "estado de litigio",
              pt: "situação de litígio",
              "zh-CN": "诉讼状态",
              ja: "訴訟状況",
              ko: "소송현황",
              vi: "tình trạng kiện tụng"
            }
          }
        }
        before do
          allow(TranslationService).to receive(:new).and_return(translation_service = instance_double(TranslationService))

          translation_map.each do |original, translation|
            translation.each do |language, text|
              allow(translation_service).to receive(:call).with(original.to_s.gsub("_", " "), I18n.locale, language)
                .and_return(text)
            end
          end
        end
        it "translates all the fields" do
          subject
          translation_map.each do |original, translation|
            translation.each do |language, text|
              I18n.with_locale(language) do
                expect(entity.send(original)).to eq(text)
                expect(entity.translation.send("#{original}_translated_from")).to eq(original_locale.to_s)
              end
            end
          end
        end
      end

      context "when the translation service raises an error" do
        before do
          allow(TranslationService).to receive(:new).and_return(translation_service = instance_double(TranslationService))
          allow(translation_service).to receive(:call).and_raise(StandardError)
        end
        it "notifies Sentry and raises a TranslationException" do
          expect(Sentry).to receive(:capture_exception)
          expect(entity).not_to receive(:save)
          expect { subject }.to raise_error(TranslationJob::TranslationException)
        end
      end
    end
  end
end
