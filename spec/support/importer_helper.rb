module ImporterHelper
  def fixture_file_upload(path, mime_type = nil, binary = false)
    unless File.exist?(path)
      path = File.join(self.class.fixture_path, "data_import", path) unless File.exist?(path)
    end

    Rack::Test::UploadedFile.new(path, mime_type, binary)
  end
end
