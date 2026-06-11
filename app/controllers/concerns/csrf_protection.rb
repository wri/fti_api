# frozen_string_literal: true

# Double-submit CSRF protection for cookie-authenticated state-changing
# requests. The XSRF-TOKEN cookie is not HTTP-only so the frontend JS can
# copy its value into the X-XSRF-TOKEN header on unsafe requests; a
# cross-site page cannot read the cookie (same-origin policy) and so cannot
# forge the header. Requests that are not authenticated via the auth cookie
# are exempt.
#
# Depends on the including controller exposing #user_id_from_auth_cookie.
module CsrfProtection
  extend ActiveSupport::Concern

  CSRF_COOKIE_NAME = "XSRF-TOKEN"
  CSRF_HEADER = "X-XSRF-TOKEN"

  included do
    before_action :verify_csrf_token!
  end

  def csrf_cookie_name
    [params[:app], CSRF_COOKIE_NAME].compact.join("_")
  end

  protected

  def verify_csrf_token!
    return if request.get? || request.head? || request.options?
    return if user_id_from_auth_cookie.blank?

    expected = cookies[csrf_cookie_name].to_s
    provided = request.headers[CSRF_HEADER].to_s
    return if expected.present? && expected.bytesize == provided.bytesize &&
      ActiveSupport::SecurityUtils.fixed_length_secure_compare(expected, provided)

    # cookie-authed but the XSRF cookie is missing (cleared by the browser,
    # an extension, etc.) — re-issue one so the frontend can read it and
    # retry the request. The current request still fails CSRF since the
    # caller had no token to send. Safe to do under the same-origin policy:
    # only same-origin JS can read the new cookie.
    set_csrf_cookie if expected.blank?

    render json: {errors: [{status: 403, title: "Invalid CSRF token"}]}, status: :forbidden
  end

  # The XSRF-TOKEN cookie is intentionally NOT httponly so the frontend JS can
  # read it and echo the value back as X-XSRF-TOKEN on unsafe requests;
  # verify_csrf_token! compares the two using a constant-time check. `expires`
  # is opt-in so login can match its lifetime to remember_me while the
  # re-issue path defaults to a browser session cookie.
  def set_csrf_cookie(expires: nil)
    cookie = {
      value: SecureRandom.urlsafe_base64(32),
      same_site: :strict,
      secure: Rails.env.production? || Rails.env.staging?,
      httponly: false
    }
    cookie[:expires] = expires if expires
    cookies[csrf_cookie_name] = cookie
  end
end
