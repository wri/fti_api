# frozen_string_literal: true

module ApiUploads
  extend ActiveSupport::Concern

  included do
    after_action :clean_file_tmp, only: [:update, :create]

    private

      def process_file_base64(file_base64)
        filename = 'file'
        content_type, _encoding, file_base64_string = file_base64.split(/[:;,]/)[1..3]

        @file_tmp = Tempfile.new(filename)
        @file_tmp.binmode
        @file_tmp.write(Base64.decode64(file_base64_string))
        @file_tmp.rewind

        content_type = "file --mime -b #{content_type}"

        extension = content_type.split('/').last
        filename += ".#{extension}" if extension

        ActionDispatch::Http::UploadedFile.new({
          tempfile: @file_tmp,
          type: content_type,
          filename: filename
        })
      end

      def clean_file_tmp
        if @file_tmp.present?
          @file_tmp.close
          @file_tmp.unlink
          CarrierWave.clean_cached_files! 1
        end
      end
  end

  class_methods do
  end
end
