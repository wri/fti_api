# frozen_string_literal: true

# Request and acceptance specs select the current user via the X-Test-User-Id
# header instead of driving a full cookie login. This keeps authentication
# deterministic per request (each request picks its own user) while leaving the
# real cookie-based resolution in place — when the header is absent we fall back
# to super, so specs that exercise the genuine login flow (e.g. sessions_spec)
# still go through the encrypted auth cookie. Because no auth cookie is involved
# on the header path, such requests are exempt from CSRF, mirroring how an
# unauthenticated-via-cookie request behaves.
module TestAuthentication
  TEST_USER_HEADER = "X-Test-User-Id"

  def user_id_from_token
    request.headers[TEST_USER_HEADER].presence || super
  end
end

# This is a header-driven authentication backdoor: it must never be installed in
# an environment that serves real traffic. It only loads via rails_helper (which
# requires spec/support/**), so production never sees it — but fail loud if that
# assumption is ever violated rather than silently weakening auth.
raise "TestAuthentication must only be loaded in the test environment" unless Rails.env.test?

APIController.prepend(TestAuthentication)
