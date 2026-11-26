# frozen_string_literal: true

module ActiveAdmin
  # Preloads the admin theme font so text renders in Inter from the first paint (see admin_theme/_fonts.scss)
  module FontPreloadExtension
    def build_active_admin_head
      super
      within head do
        text_node helpers.tag.link(rel: "preload", href: helpers.font_path("inter/inter-latin.woff2"), as: "font", type: "font/woff2", crossorigin: "anonymous")
      end
    end
  end
end
