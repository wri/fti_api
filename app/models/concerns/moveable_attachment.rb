# frozen_string_literal: true

module MoveableAttachment
  extend ActiveSupport::Concern

  included do
    private

    uploaders.each_key do |uploader|
      define_method "move_#{uploader}_to_public_directory" do
        return unless attachment

        from = File.dirname(attachment.file.file.gsub('/public/', '/private/'))
        to = File.dirname(from.gsub('/private/', '/public/'))
        move_attachment(from: from, to: to)
      end

      define_method "move_#{uploader}_to_private_directory" do
        return unless attachment

        from = File.dirname(attachment.file.file.gsub('/private/', '/public/'))
        to = File.dirname(from.gsub('/public/', '/private/'))
        move_attachment(from: from, to: to)
      end
    end

    def move_attachment(from:, to:)
      FileUtils.makedirs(to)
      system "mv -f #{from} #{to}"
    end
  end
end
