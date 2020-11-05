module IntegrationHelper
  ERRORS = {
    '401' => { status: '401', title: 'You are not authorized to access this page.' },
    '422' => { status: 422, title: 'Unprocessable entity.' },
    '422_undefined_user' => { status: 422, title: "Couldn't find the user with this email" },
  }.freeze

  def default_status_errors(*attributes)
    { errors: ERRORS.values_at(*attributes.map(&:to_s)).compact }
  end

  def parsed_data
    parsed_body[:data]
  end

  def parsed_attributes
    parsed_data[:attributes]
  end

  def first_parsed_attributes
    parsed_data.first[:attributes]
  end

  def parsed_body
    Oj.load(response.body, symbol_keys: true)
  end

  def parsed_error
    parsed_body[:error]
  end

  def login_user(user)
    post('/login',
         params: { auth: { email: user.email, password: user.password }},
         headers: webuser_headers)
  end

  def generate_token(id)
    JWT.encode({ user: id }, ENV['AUTH_SECRET'], 'HS256')
  end

  def webuser
    @webuser ||= create(:webuser)
  end

  def webuser_token
    @webuser_token ||= generate_token(webuser.id)
  end

  def webuser_headers
    @webuser_headers ||= {
      'HTTP_OTP_API_KEY' => "Bearer #{webuser_token}",
      'Content-Type' => 'application/vnd.api+json',
      'HTTP_ACCEPT' => 'application/vnd.api+json'
    }
  end

  def non_api_webuser_headers
    @non_api_webuser_headers ||= {
      'HTTP_OTP_API_KEY' => "Bearer #{webuser_token}",
    }
  end

  def admin
    @admin ||= create(:admin)
  end

  def admin_headers
    @admin_headers ||= authorize_headers(admin.id)
  end

  def user
    @user ||= create(:user)
  end

  def user_headers
    @user_headers ||= authorize_headers(user.id)
  end

  def authorize_headers(id, jsonapi: true)
    headers = {
      'Authorization' => "Bearer #{generate_token(id)}",
      'HTTP_OTP_API_KEY' => "Bearer #{webuser_token}",
    }

    return headers unless jsonapi

    headers.merge!(
      'Content-Type' => 'application/vnd.api+json',
      'HTTP_ACCEPT' => 'application/vnd.api+json'
    )
  end

  def jsonapi_errors(status, code, errors = {})
    api_errors = []

    errors.each do |attribute, messages|
      messages.each do |message|
        error = {
          title: message,
          detail: "#{attribute} - #{message}",
          code: code.to_s,
          source: { pointer: "/data/attributes/#{attribute}" },
          status: status.to_s
        }

        api_errors << error
      end
    end

    { errors: api_errors }
  end

  def jsonapi_params(type, id = nil, attributes = nil)
    params = { data: { type: type } }

    if id.present?
      params[:data][:id] = id.to_s
    end

    if attributes.present?
      params[:data][:attributes] = attributes
    end

    params.to_json
  end
end
