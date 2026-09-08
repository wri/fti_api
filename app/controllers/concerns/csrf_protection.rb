# frozen_string_literal: true

# Double-submit CSRF protection for cookie-authenticated state-changing
# requests. The XSRF-TOKEN cookie is not HTTP-only so the frontend JS can
# copy its value into the X-XSRF-TOKEN header on unsafe requests; a
# cross-site page cannot read the cookie (same-origin policy) and so cannot
# forge the header. Unauthenticated requests are exempt.
#
# Depends on the including controller exposing #auth_cookie_user and #app_name.
module CsrfProtection
  extend ActiveSupport::Concern

  CSRF_COOKIE_NAME = "XSRF-TOKEN"
  CSRF_HEADER = "X-XSRF-TOKEN"
  CSRF_VERIFIER_SALT = "csrf_token"

  included do
    before_action :verify_csrf_token!
  end

  # Same key derivation as Rails.application.message_verifier, but url_safe so
  # the signed value survives document.cookie unencoded — unlike every other
  # signed value here, the frontend has to read this one and echo it back.
  def self.verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(
      Rails.application.key_generator.generate_key(CSRF_VERIFIER_SALT),
      serializer: JSON,
      url_safe: true
    )
  end

  def csrf_cookie_name
    [app_name, CSRF_COOKIE_NAME].compact.join("_")
  end

  protected

  def verify_csrf_token!
    return if request.get? || request.head? || request.options?

    user_id = auth_cookie_user&.id
    return if user_id.blank?
    return if valid_csrf_token?(user_id)

    # cookie-authed but the XSRF cookie is missing (cleared by the browser,
    # an extension, etc.) — re-issue one so the frontend can read it and
    # retry the request. The current request still fails CSRF since the
    # caller had no token to send. Safe to do under the same-origin policy:
    # only same-origin JS can read the new cookie.
    set_csrf_cookie(user_id) if cookies[csrf_cookie_name].blank?

    render json: {errors: [{status: 403, title: "Invalid CSRF token"}]}, status: :forbidden
  end

  # Cookie and header must match, and the token has to carry a valid signature
  # over the id of the user the auth cookie resolved to — so a token minted for
  # one session is not accepted for another.
  def valid_csrf_token?(user_id)
    expected = cookies[csrf_cookie_name].to_s
    provided = request.headers[CSRF_HEADER].to_s

    return false unless expected.present? && expected.bytesize == provided.bytesize &&
      ActiveSupport::SecurityUtils.fixed_length_secure_compare(expected, provided)

    csrf_verifier.verified(expected)&.dig("user_id") == user_id
  end

  # The XSRF-TOKEN cookie is intentionally NOT httponly so the frontend JS can
  # read it and echo the value back as X-XSRF-TOKEN on unsafe requests. The
  # signed value contains no secret; the nonce just rotates it per login.
  # `expires` is opt-in so login can match its lifetime to remember_me while the
  # re-issue path defaults to a browser session cookie.
  def set_csrf_cookie(user_id, expires: nil)
    cookie = {
      value: csrf_verifier.generate({"user_id" => user_id, "nonce" => SecureRandom.urlsafe_base64(16)}),
      same_site: :strict,
      secure: Rails.env.production? || Rails.env.staging?,
      httponly: false
    }
    cookie[:expires] = expires if expires
    cookies[csrf_cookie_name] = cookie
  end

  def csrf_verifier
    CsrfProtection.verifier
  end
end
