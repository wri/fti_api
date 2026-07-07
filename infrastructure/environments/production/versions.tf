terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state in S3 with native locking (use_lockfile). Create the bucket first via ../../remote-state,
  # then `terraform init -migrate-state`.
  backend "s3" {
    bucket       = "otp-terraform-state"
    key          = "production/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "OTP"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
