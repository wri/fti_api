# frozen_string_literal: true

module MoveableAttachment
  extend ActiveSupport::Concern

  included do
    private

    uploaders.each_key do |uploader_name|
      define_method "move_#{uploader_name}_to_public_directory" do
        uploader = send(uploader_name)
        return if uploader.nil?
        return if uploader.file.nil?

        public_uploads = uploader.public_root.join("uploads").to_s
        private_uploads = uploader.private_root.join("uploads").to_s
        from = File.dirname(uploader.file.file.gsub(public_uploads, private_uploads))
        to = File.dirname(from.gsub(private_uploads, public_uploads))
        move_attachment(from, to)
      end

      define_method "move_#{uploader_name}_to_private_directory" do
        uploader = send(uploader_name)
        return if uploader.nil?
        return if uploader.file.nil?

        public_uploads = uploader.public_root.join("uploads").to_s
        private_uploads = uploader.private_root.join("uploads").to_s
        from = File.dirname(uploader.file.file.gsub(private_uploads, public_uploads))
        to = File.dirname(from.gsub(public_uploads, private_uploads))
        move_attachment(from, to)
      end
    end

    def move_attachment(from, to)
      FileUtils.makedirs(to)
      system "rsync -a #{from} #{to}"
      system "rm -rf #{from}"
    end
  end
end
