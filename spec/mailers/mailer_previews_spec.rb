require "rails_helper"

# quick smoke tests for all mail previews
describe "Mail Previews", type: :request do
  before(:all) do
    # make sure to add all data needed for all mailers
    # doing it in before all for better performance
    country = create(:country)

    create_list(:required_operator_document_country, 3, country: country)

    operator = create(:operator, :with_documents, country: country)
    create(:operator_user, operator: operator, country: country)

    # operator mailer needs expired and expiring documents
    operator.operator_documents.doc_not_provided.first.update!(
      document_file: create(:document_file), status: "doc_expired", start_date: 10.days.ago, expire_date: 2.days.ago
    )
    operator.operator_documents.doc_valid.first.update!(start_date: 10.days.ago, expire_date: 10.days.from_now)
  end

  ActionMailer::Preview.all.each do |preview| # rubocop:disable Rails/FindEach
    next if preview.emails.empty?

    describe preview.preview_name do
      preview.emails.each do |email|
        describe email do
          %w[html txt].each do |format|
            %w[en fr].each do |locale|
              context "with format #{format} and locale #{locale}" do
                it "renders successfuly" do
                  get "/rails/mailers/#{preview.preview_name}/#{email}.#{format}?locale=#{locale}"

                  expect(response).to be_successful
                end
              end
            end
          end
        end
      end
    end
  end
end
