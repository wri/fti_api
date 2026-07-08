variable "name" {
  description = "Name prefix for network resources (e.g. otp-staging)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet the host runs in."
  type        = string
  default     = "10.0.1.0/24"
}
