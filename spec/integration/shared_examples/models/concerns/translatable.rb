RSpec.shared_examples "translatable" do |factory_key, fields|
  let(:model) { create(factory_key) }

  fields.each do |field|
    context "##{field}" do
      it "is a translatable field" do
        expect(model.translated_attribute_names).to include(field)
      end

      it "creates fallback for all languages" do
        (I18n.available_locales - [I18n.locale]).each do |locale|
          field_in_default_locale = model.send(field)
          I18n.with_locale(locale) do
            expect(model.send(field)).to eq(field_in_default_locale)
          end
        end
      end

      context "when translation exists" do
        it "return existing translation" do
          original_value = model.send(field)
          model.update(field => "New translation FR", :locale => :fr)

          I18n.locale = :fr
          expect(model.send(field)).to eq("New translation FR")

          I18n.locale = :en
          expect(model.send(field)).to eq(original_value)
        end
      end
    end
  end
end
