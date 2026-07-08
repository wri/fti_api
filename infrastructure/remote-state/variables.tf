variable "region" {
  description = "Region the state bucket lives in. Holds state for all environments regardless of where their resources run."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
  default     = "otp-wri-tf-state"
}
