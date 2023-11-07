RSpec.shared_examples "mail_preview" do |with_locales: %w[en fr], formats: %w[txt html]|
  let(:preview) { described_class }
  let(:preview_email) { self.class.parent_groups[2].description }

  formats.each do |format|
    with_locales.each do |locale|
      describe "with locale #{locale} and format #{format}" do
        it "renders a successful response" do
          get "/rails/mailers/#{preview.preview_name}/#{preview_email}.#{format}?locale=#{locale}"

          expect(response).to be_successful
        end
      end
    end
  end
end
