require 'rails_helper'
require 'carrierwave/test/matchers'

RSpec.describe DocumentUploader do
  include CarrierWave::Test::Matchers

  before :each do
    DocumentUploader.enable_processing = true
    @document = create(:document)
    @uploader = DocumentUploader.new(@document, Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'doc.pdf')))
    @uploader.store!(File.open(File.join(Rails.root, 'spec', 'support', 'files', 'doc.pdf')))
  end

  after :each do
    @uploader.remove!
    DocumentUploader.enable_processing = false
  end

  it 'makes the document readable only to the owner and not executable' do
    expect(@uploader).to have_permissions(0644)
  end
end
