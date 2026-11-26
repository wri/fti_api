module Admin
  module Components
    class Header < Arbre::HTML::Tag
      builder_method :html5_header
    end

    class Dialog < Arbre::HTML::Tag
      builder_method :dialog
      attr_accessor :inner_content

      def build(attributes = {})
        title = attributes[:title]
        super(attributes.except(:title))
        html5_header do
          strong title if title.present?
          close_label = I18n.t("active_admin.shared.close")
          button type: "button", title: close_label, "aria-label": close_label, class: "close-dialog-button" do
            text_node '<svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true"><path d="M4 4l8 8M12 4l-8 8" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" /></svg>'.html_safe
          end
        end
        # initial focus goes to the content instead of the close button
        @inner_content = div tabindex: "-1", autofocus: true
      end

      def add_child(child)
        if @inner_content
          @inner_content.add_child child
        else
          super
        end
      end

      delegate :children?, to: :@inner_content
    end
  end
end
