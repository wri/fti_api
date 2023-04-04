module ActiveAdmin
  module PaperTrail
    module ShowPageExtension
      def main_content
        return version_error_message if params[:version] && resource.paper_trail.live?

        super
      end

      def version_error_message
        panel "Error" do
          "There is a problem with displaying this version."
        end
      end
    end
  end
end
