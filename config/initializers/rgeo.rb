# Monkey patches this method (it's super slow)
module RGeo
  module Cartesian
    module LineStringMethods
      def is_simple?
        true
      end
    end
  end
end
