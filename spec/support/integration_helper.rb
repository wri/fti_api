module IntegrationHelper
  FACTORY_PASSWORD = "Supersecret1"

  ERRORS = {
    "401" => {status: 401, title: "You are not authorized to access this page."},
    "422" => {status: 422, title: "Unprocessable entity."},
    "422_undefined_user" => {status: 422, title: "Couldn't find the user with this email"}
  }.freeze

  def default_status_errors(*attributes)
    {errors: ERRORS.values_at(*attributes.map(&:to_s)).compact}
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

  def extract_operator_document_id
    parsed_data.map { |h| h[:attributes][:"operator-document-id"] }.compact
  end

  def parsed_error
    parsed_body[:error]
  end

  def login_user(user)
    post("/login",
      params: {auth: {email: user.email, password: user.password}},
      headers: jsonapi_headers)
  end

  def admin
    @admin ||= create(:admin)
  end

  def admin_headers
    authorize_headers(admin.id)
  end

  def user
    @user ||= create(:user)
  end

  def user_headers
    authorize_headers(user.id)
  end

  def operator_user
    @operator_user ||= create(:operator_user)
  end

  def operator_user_headers
    authorize_headers(operator_user.id)
  end

  # Logs the user in for real and hands back the headers a browser would send.
  # The auth cookie lands in the shared jar as a side effect, so the login has
  # to happen immediately before the request it authorizes — hence no
  # memoization on the *_headers helpers: whichever role logged in last owns
  # the jar, and re-logging in per call keeps each request honest.
  #
  # Every user factory inherits the same password, so an id is enough to log in.
  def authorize_headers(id, jsonapi: true, app: nil)
    user = User.find(id)
    url = "/login"
    url += "?app=#{app}" if app.present?
    post url, params: {auth: {email: user.email, password: FACTORY_PASSWORD}}

    # both cookies are namespaced per app, so a request sent with ?app= only
    # authenticates against a login made for that same app
    csrf_cookie_name = [app, APIController::CSRF_COOKIE_NAME].compact.join("_")
    # unsafe requests need the double-submit token echoed back from the cookie
    headers = {APIController::CSRF_HEADER => cookies[csrf_cookie_name]}
    headers.merge!(jsonapi_headers) if jsonapi
    headers
  end

  def jsonapi_headers
    {
      "Content-Type" => "application/vnd.api+json",
      "HTTP_ACCEPT" => "application/vnd.api+json"
    }
  end

  # the raw Set-Cookie header entry for the auth cookie, so expiry attributes
  # (expires/max-age) can be asserted on
  def auth_set_cookie_header
    Array(response.headers["Set-Cookie"]).find { |c| c.start_with?("#{APIController::AUTH_COOKIE_NAME}=") }
  end

  def initialize_download_session(user_headers, app: nil)
    url = "/sessions/download-session"
    url += "?app=#{app}" if app.present?
    post url, headers: user_headers
  end

  def jsonapi_errors(status, code, errors = {})
    api_errors = []

    errors.each do |attribute, messages|
      pointer = if attribute.to_s.start_with?("relationships_")
        :relationships
      else
        :attributes
      end
      attribute = attribute.to_s.gsub("relationships_", "")

      messages.each do |message|
        error = {
          title: message,
          detail: "#{attribute} - #{message}",
          code: code.to_s,
          source: {pointer: "/data/#{pointer}/#{attribute}"},
          status: status.to_s
        }

        api_errors << error
      end
    end

    {errors: api_errors}
  end

  def jsonapi_params(type, id = nil, attributes = nil)
    params = {data: {type: type}}

    if id.present?
      params[:data][:id] = id.to_s
    end

    if attributes.present?
      params[:data][:attributes] = attributes.except(:relationships)
      relationships = attributes[:relationships]

      if relationships.present?
        params[:data][:relationships] = relationships.map do |model, value|
          if value.is_a? Array
            {
              model => {
                data: value.map do |v|
                  {
                    type: model.to_s.pluralize,
                    id: v.to_s
                  }
                end
              }
            }
          else
            {
              model => {
                data: {
                  type: model.to_s.pluralize,
                  id: value.to_s
                }
              }
            }
          end
        end.reduce(&:merge)
      end
    end

    params.to_json
  end

  def try_to_call(callable_or_not)
    callable_or_not.respond_to?(:call) ? instance_exec(&callable_or_not) : callable_or_not
  end

  def base64_file_data(filepath)
    "data:application/pdf;base64,#{Base64.encode64(File.read(filepath))}"
  end
end
