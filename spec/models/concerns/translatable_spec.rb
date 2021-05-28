RSpec.shared_examples 'translatable' do |model, fields|
  fields.each do |field|
    context "##{field}" do
      it 'is a translatable field' do
        expect(model.translated_attribute_names).to include(field)
      end

      context 'when translation does not exist' do
        it 'fallback for empty translation' do
          expect(model.send(field)).to match(model.send(field))
        end
      end

      context 'when translation exists' do
        it 'return existing translation' do
          original_value = model.send(field)
          model.update(field => 'New translation FR', locale: :fr)

          I18n.locale = :fr
          expect(model.send(field)).to eq('New translation FR')

          I18n.locale = :en
          expect(model.send(field)).to eq(original_value)
        end
      end
    end
  end
end
