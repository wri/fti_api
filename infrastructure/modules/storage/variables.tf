variable "bucket_name" {
  description = "Globally unique S3 bucket name (e.g. otp-staging)."
  type        = string
}

variable "backup_retention_days" {
  description = "Days to retain objects under the db-backups/ prefix before expiry."
  type        = number
  default     = 30
}

variable "cors_allowed_origins" {
  description = "Origins allowed for direct browser access. Empty disables CORS config."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to storage resources."
  type        = map(string)
  default     = {}
}
