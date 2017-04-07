# frozen_string_literal: true

class APIVersion
  def initialize(options)
    @version = options[:version]
    @default = options[:current]
  end

  def matches?(request)
    @default || check_headers(request.headers)
  end

  private

    def check_headers(headers)
      accept = headers['Accept']
      accept && accept.include?("application/fti-api-v#{@version}+json")
    end
end
