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
          button "X", title: "Close", class: "button close-dialog-button"
        end
        @inner_content = div
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
