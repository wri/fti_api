require "rails_helper"

# quick smoke tests for all mail previews
describe "Mail Previews", type: :request do
  before(:all) do
    # make sure to add all data needed for all mailers
    # doing it in before all for better performance
    country = create(:country)

    ngo_user = create(:ngo, country: country)
    create_list(:required_operator_document_country, 3, country: country)

    operator = create(:operator, :with_documents, country: country)
    create(:operator_user, operator: operator, country: country)

    # operator mailer needs expired and expiring documents
    operator.operator_documents.doc_not_provided.first.update!(
      document_file: create(:document_file), status: "doc_expired", start_date: 10.days.ago, expire_date: 2.days.ago
    )
    operator.operator_documents.doc_valid.first.update!(start_date: 10.days.ago, expire_date: 10.days.from_now)

    # observation mailer needs observation
    admin = create(:admin)
    create(
      :observation,
      admin_comment: "admin comment",
      monitor_comment: "monitor comment",
      responsible_admin: admin,
      country: country,
      modified_user: ngo_user
    )
  end

  ActionMailer::Preview.all.each do |preview|
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
