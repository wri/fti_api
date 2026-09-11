# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # base64 data URIs are whole uploaded files (mount_base64_uploader), log only their type and size
  ->(_key, value) {
    if value.is_a?(String) && value.start_with?("data:")
      value.replace("[FILTERED #{value[/\Adata:[^;,]{0,100}/]} #{value.bytesize} bytes]")
    end
  }
]
