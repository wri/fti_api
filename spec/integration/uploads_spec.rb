# frozen_string_literal: true

require "rails_helper"

RSpec.describe UploadsController, type: :request do
  before(:all) do
    @etc_dir = Rails.root.join("tmp", "etc")
    FileUtils.mkdir_p(ApplicationUploader.new.root.join("uploads"))
    FileUtils.mkdir_p(@etc_dir)

    @observation_report = create(:observation_report)
    @document_file = create(:document_file) # operator_document_file
    @donor = create(:donor) # donor logo

    File.write(@etc_dir.join("passwd.txt"), "private")
  end

  before do
    allow(TrackFileDownloadJob).to receive(:perform_later)
  end

  describe "GET /uploads/*path" do
    context "successful file downloads" do
      it "downloads existing files" do
        get @document_file.attachment.url

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Disposition"]).to include("inline")
      end
    end

    context "file not found scenarios" do
      it "returns 404 for non-existent files" do
        get "/uploads/operator_document_file/123/456/nonexistent.pdf"

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for non-existent directories" do
        get "/uploads/operator_document_file/999/888/test.pdf"

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for existing files but not in db" do
        new_file = File.join(File.dirname(@document_file.attachment.file.file), "newfile.txt")
        File.write(new_file, "test")

        get "/uploads/operator_document_file/attachment/#{@document_file.id}/newfile.txt"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "invalid path handling" do
      it "returns 404 for insufficient path segments" do
        get "/uploads/operator_document_file/123.pdf"

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for unknown models" do
        get "/uploads/unknown_model/123/456/test.pdf"

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for empty paths" do
        get "/uploads/.pdf"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "download tracking" do
      it "tracks downloads for trackable models with regular browsers" do
        allow_any_instance_of(UploadsController).to receive(:client_id).and_return("test-client-id")

        get @document_file.attachment.url, headers: {
          "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }

        expect(response).to have_http_status(:ok)
        expect(TrackFileDownloadJob).to have_received(:perform_later).with(
          "test-client-id", request.remote_ip, request.referer, "direct", nil, request.url, @document_file.attachment.filename, "document_file"
        )

        get @observation_report.attachment.url, headers: {
          "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }

        expect(response).to have_http_status(:ok)
        expect(TrackFileDownloadJob).to have_received(:perform_later).with(
          "test-client-id", request.remote_ip, request.referer, "direct", nil, request.url, @observation_report.attachment.filename, "observation_report"
        )
      end

      it "does not track bot requests" do
        get @document_file.attachment.url, headers: {
          "User-Agent" => "Googlebot/2.1"
        }

        expect(response).to have_http_status(:ok)
        expect(TrackFileDownloadJob).not_to have_received(:perform_later)
      end

      it "does not track admin panel requests" do
        admin_referers = [
          "https://example.com/admin",
          "https://example.com/admin/documents",
          "https://example.com/observations-tool",
          "https://example.com/observations-tool/reports"
        ]

        admin_referers.each do |referer|
          get @document_file.attachment.url, headers: {
            "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Referer" => referer
          }

          expect(response).to have_http_status(:ok)
          expect(TrackFileDownloadJob).not_to have_received(:perform_later)
        end
      end

      it "does not track for not trackable model" do
        get @donor.logo.url, headers: {
          "User-Agent" => "Mozilla/5.0 (Chrome/91.0) Safari/537.36"
        }

        expect(response).to have_http_status(:ok)
        expect(TrackFileDownloadJob).not_to have_received(:perform_later)
      end
    end

    context "special paper trail history handling" do
      # gov document keeps history of changed attachments - not removing files after update
      let(:gov_document) { create(:gov_document, :file) }

      before do
        @previous_url = gov_document.attachment.url

        gov_document.attachment = Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "doc.pdf"))
        gov_document.save!

        expect(@previous_url).not_to eq(gov_document.attachment.url)
      end

      it "returns 404 for previous version" do
        get @previous_url

        expect(response).to have_http_status(:not_found)
      end

      context "when admin user" do
        before { sign_in admin }

        it "allows access to previous history attachment" do
          get @previous_url

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Disposition"]).to include("inline")
        end
      end
    end

    context "soft deleted records handling" do
      let(:gov_document) { create(:gov_document, :file) }

      before { gov_document.destroy! }

      it "returns 404 for soft deleted records" do
        get gov_document.attachment.url

        expect(response).to have_http_status(:not_found)
      end

      context "when admin user" do
        before { sign_in admin }

        it "allows access to soft deleted records" do
          get gov_document.attachment.url

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Disposition"]).to include("inline")
        end
      end
    end

    context "edge cases and error handling" do
      it "handles requests without user agent" do
        get @observation_report.attachment.url

        expect(response).to have_http_status(:ok)
        expect(TrackFileDownloadJob).to have_received(:perform_later)
      end

      it "handles requests without referer" do
        get @document_file.attachment.url, headers: {
          "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }

        expect(response).to have_http_status(:ok)
        expect(TrackFileDownloadJob).to have_received(:perform_later)
      end

      it "prevents directory traversal" do
        get "/uploads/operator_document_file/../../etc/passwd.txt"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
