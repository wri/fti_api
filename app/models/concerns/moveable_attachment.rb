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

        from = File.dirname(uploader.file.file.gsub("/public/", "/private/"))
        to = File.dirname(from.gsub("/private/", "/public/"))
        move_attachment(from, to)
      end

      define_method "move_#{uploader_name}_to_private_directory" do
        uploader = send(uploader_name)
        return if uploader.nil?
        return if uploader.file.nil?

        from = File.dirname(uploader.file.file.gsub("/private/", "/public/"))
        to = File.dirname(from.gsub("/public/", "/private/"))
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
