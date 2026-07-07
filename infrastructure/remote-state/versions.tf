terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # This config uses LOCAL state on purpose: it creates the very bucket that every
  # other config uses as a backend, so it can't use that bucket for its own state
  # (chicken-and-egg). This state only tracks the state bucket itself; if lost, the
  # bucket is trivially re-adopted with `terraform import`.
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "OTP"
      ManagedBy = "terraform"
      Component = "tf-state-backend"
    }
  }
}
