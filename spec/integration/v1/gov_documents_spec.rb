require 'rails_helper'

module V1
  describe 'GovDocuments', type: :request do
    it_behaves_like "jsonapi-resources", GovDocument, {
      show: {},
      pagination: {},
      route_key: 'gov-documents'
    }

    let(:country) { create(:country) }
    let(:gov_document) { create(:gov_document, country: country) }
    let(:user) { create(:government_user, country: country) }
    let(:user_headers) { authorize_headers(user.id) }

    describe 'Show documents' do
      let!(:gov_link) { create(:gov_document, :link, force_status: 'doc_pending', country: country) }
      let!(:gov_link_valid) { create(:gov_document, :link, force_status: 'doc_valid', country: country) }
      let!(:gov_file) { create(:gov_document, :file, force_status: 'doc_pending', country: country) }
      let!(:gov_file_valid) { create(:gov_document, :file, force_status: 'doc_valid', country: country) }
      let!(:gov_stats) { create(:gov_document, :stats, force_status: 'doc_pending', country: country) }
      let!(:gov_stats_valid) { create(:gov_document, :stats, force_status: 'doc_valid', country: country) }

      subject do
        get "/gov-documents?include=required-gov-document,required-gov-document.required-gov-document-group", headers: user_headers
      end

      before { subject }

      context 'when public user' do
        let(:user_headers) { non_api_webuser_headers }

        it 'shows attributes only for valid documents', :aggregate_failures do
          expect(status).to eq(200)

          find_doc_attributes = -> (doc) { parsed_data.find { |d| d[:id] == doc.id.to_s }[:attributes] }
          returned_gov_link = find_doc_attributes.call(gov_link)
          returned_gov_link_valid = find_doc_attributes.call(gov_link_valid)
          returned_gov_file = find_doc_attributes.call(gov_file)
          returned_gov_file_valid = find_doc_attributes.call(gov_file_valid)
          returned_gov_stats = find_doc_attributes.call(gov_stats)
          returned_gov_stats_valid = find_doc_attributes.call(gov_stats_valid)

          expect(returned_gov_link).to include(
            status: 'doc_not_provided',
            link: nil
          )
          expect(returned_gov_link_valid).to include(
            status: 'doc_valid',
            link: gov_link_valid.link
          )
          expect(returned_gov_file).to include(
            status: 'doc_not_provided',
            attachment: { url: nil }
          )
          expect(returned_gov_file_valid).to include(
            status: 'doc_valid',
            attachment: { url: gov_file_valid.attachment.to_s }
          )
          expect(returned_gov_stats).to include(
            status: 'doc_not_provided',
            value: nil,
            units: nil
          )
          expect(returned_gov_stats_valid).to include(
            status: 'doc_valid',
            value: gov_stats_valid.value,
            units: gov_stats_valid.units,
          )
        end
      end

      context 'when government' do
        it 'shows all attributes' do
          expect(status).to eq(200)

          find_doc_attributes = -> (doc) { parsed_data.find { |d| d[:id] == doc.id.to_s }[:attributes] }
          returned_gov_link = find_doc_attributes.call(gov_link)
          returned_gov_link_valid = find_doc_attributes.call(gov_link_valid)
          returned_gov_file = find_doc_attributes.call(gov_file)
          returned_gov_file_valid = find_doc_attributes.call(gov_file_valid)
          returned_gov_stats = find_doc_attributes.call(gov_stats)
          returned_gov_stats_valid = find_doc_attributes.call(gov_stats_valid)

          expect(returned_gov_link).to include(
            status: 'doc_pending',
            link: gov_link.link
          )
          expect(returned_gov_link_valid).to include(
            status: 'doc_valid',
            link: gov_link_valid.link
          )
          expect(returned_gov_file).to include(
            status: 'doc_pending',
            attachment: { url: gov_file.attachment.to_s }
          )
          expect(returned_gov_file_valid).to include(
            status: 'doc_valid',
            attachment: { url: gov_file_valid.attachment.to_s }
          )
          expect(returned_gov_stats).to include(
            status: 'doc_pending',
            value: gov_stats.value,
            units: gov_stats.units,
          )
          expect(returned_gov_stats_valid).to include(
            status: 'doc_valid',
            value: gov_stats_valid.value,
            units: gov_stats_valid.units,
          )
        end
      end
    end

    describe 'Remove document' do
      subject do
        delete "/gov-documents/#{gov_document.id}", headers: user_headers
      end

      before { subject }

      describe 'errors' do
        context 'when public user' do
          let(:user_headers) { non_api_webuser_headers }

          it 'should return not authenticated error' do
            expect(parsed_body).to eq(default_status_errors(401))
            expect(status).to eq(401)
          end
        end

        context 'when not authorized user' do
          let(:user_headers) { authorize_headers(create(:government_user, country: create(:country)).id) }

          it 'should return not authorized error' do
            expect(parsed_body).to eq(default_status_errors(401))
            expect(status).to eq(401)
          end
        end
      end

      it 'is successful and changes state to not provided' do
        expect(status).to eq(204)
        gov_document.reload
        expect(gov_document.start_date).to be_nil
        expect(gov_document.expire_date).to be_nil
        expect(gov_document.link).to be_nil
        expect(gov_document.status).to eq('doc_not_provided')
        expect(gov_document.user).to be_nil
        expect(gov_document.uploaded_by).to be_nil
      end
    end

    describe 'Update document' do
      let(:params) { { 'start-date': '2022-10-10' } }

      subject do
        patch "/gov-documents/#{gov_document.id}",
          params: jsonapi_params('gov-documents', gov_document.id, params),
          headers: user_headers
      end

      before { subject }

      describe 'errors' do
        context 'when public user' do
          let(:user_headers) { non_api_webuser_headers }

          it 'should return not authenticated error' do
            expect(parsed_body).to eq(default_status_errors(401))
            expect(status).to eq(401)
          end
        end

        context 'when not authorized user' do
          let(:user_headers) { authorize_headers(create(:government_user, country: create(:country)).id) }

          it 'should return not authorized error' do
            expect(parsed_body).to eq(default_status_errors(401))
            expect(status).to eq(401)
          end
        end
      end

      describe 'updating file' do
        let(:gov_document) { create(:gov_document, :file, country: country) }
        let(:params) { {
          'start-date': '2022-12-12',
          'expire-date': '2022-12-16',
          attachment: "data:application/pdf;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'doc.pdf')))}"
        } }

        it 'is successful' do
          expect(status).to eq(200)
          gov_document.reload
          expect(gov_document.start_date.strftime('%Y-%m-%d')).to eq('2022-12-12')
          expect(gov_document.expire_date.strftime('%Y-%m-%d')).to eq('2022-12-16')
          expect(gov_document.read_attribute(:attachment)).to match('.pdf')
          expect(gov_document.status).to eq('doc_pending')
          expect(gov_document.user).to eq(user)
          expect(gov_document.uploaded_by).to eq('government')
        end
      end

      describe 'updating link' do
        let(:gov_document) { create(:gov_document, link: 'https://old.com', country: country) }
        let(:params) { {
          'start-date': '2022-12-12',
          'expire-date': '2022-12-16',
          link: 'https://new-link.com'
        } }

        it 'is successful' do
          expect(status).to eq(200)
          gov_document.reload
          expect(gov_document.start_date.strftime('%Y-%m-%d')).to eq('2022-12-12')
          expect(gov_document.expire_date.strftime('%Y-%m-%d')).to eq('2022-12-16')
          expect(gov_document.link).to eq('https://new-link.com')
          expect(gov_document.status).to eq('doc_pending')
          expect(gov_document.user).to eq(user)
          expect(gov_document.uploaded_by).to eq('government')
        end
      end

      describe 'updating stats' do
        let(:gov_document) { create(:gov_document, value: '50', units: 'km2', country: country) }
        let(:params) { {
          'start-date': '2022-12-12',
          'expire-date': '2022-12-16',
          value: '100',
          units: 'm2'
        } }

        it 'is successful' do
          expect(status).to eq(200)
          gov_document.reload
          expect(gov_document.start_date.strftime('%Y-%m-%d')).to eq('2022-12-12')
          expect(gov_document.expire_date.strftime('%Y-%m-%d')).to eq('2022-12-16')
          expect(gov_document.value).to eq('100')
          expect(gov_document.units).to eq('m2')
          expect(gov_document.status).to eq('doc_pending')
          expect(gov_document.user).to eq(user)
          expect(gov_document.uploaded_by).to eq('government')
        end
      end
    end
  end
end
