# frozen_string_literal: true

# Reports requests that arrive from an origin other than our own.
#
# nginx serves every frontend from the same origin as this API (portal at /,
# observations-tool at /observations-tool/, this app at /api/), so no CORS
# middleware runs outside development and nothing legitimate is ever
# cross-origin. A request carrying a foreign Origin therefore means a frontend
# was built pointing at an absolute API URL instead of the relative /api path.
#
# The browser reports that failure to the frontend as an opaque "Failed to
# fetch" with no detail — the origin that was actually used is only visible
# here, on the receiving end, which is why the detection lives in the API.
module CrossOriginReporting
  extend ActiveSupport::Concern

  # one report per offending origin per window, so a bad deploy that retries in
  # a loop doesn't flood Sentry
  REPORT_THROTTLE = 3.hours

  # an Origin header is a serialized origin; anything longer is junk we don't
  # want to build cache keys from
  MAX_ORIGIN_LENGTH = 255

  # off unless explicitly enabled, since in development the frontends
  # legitimately run on their own ports and every request is cross-origin
  ENABLED_ENV_VAR = "SENTRY_LOG_CROSS_ORIGIN_REQUESTS"

  included do
    before_action :report_cross_origin_request
  end

  private

  # Runs before :authenticate — a cross-origin request that goes on to 401 is
  # still worth knowing about, since the misconfigured frontend is the point.
  def report_cross_origin_request
    return unless ENV[ENABLED_ENV_VAR] == "true"

    origin = request.headers["Origin"]
    # browsers omit Origin on same-origin GETs but send it on same-origin
    # POSTs, so presence alone proves nothing — it has to actually differ
    return if origin.blank? || origin == request.base_url
    return if origin.bytesize > MAX_ORIGIN_LENGTH
    return unless first_report_for?(origin)

    Sentry.capture_message(
      "API request from unexpected origin #{origin}",
      level: :error,
      tags: {request_origin: origin, app: app_name || "portal"},
      extra: {
        expected_origin: request.base_url,
        method: request.method,
        path: request.path,
        referer: request.referer
      }
    )
  end

  # #write with unless_exist is a no-op when the key is already set, so the
  # first caller in the window gets true and the rest get false. The cache is a
  # per-machine file store, so this throttles per app server — fine for a
  # diagnostic.
  def first_report_for?(origin)
    key = "cross_origin_report/#{Digest::SHA256.hexdigest(origin)}"
    Rails.cache.write(key, true, expires_in: REPORT_THROTTLE, unless_exist: true)
  end
end
