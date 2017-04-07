# frozen_string_literal: true

module ControllerAdditions
  module ClassMethods
    def load_and_authorize_resource(*args)
      cancan_resource_class.add_before_filter(self, :load_and_authorize_resource, *args)
    end
  end
end
