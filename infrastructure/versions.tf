terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Single backend for all environments. Terraform namespaces state per workspace
  # automatically (env:/staging/…, env:/production/…), so one block covers both.
  # Native S3 locking (use_lockfile) — no DynamoDB. Create the bucket first via
  # ./remote-state.
  backend "s3" {
    bucket       = "otp-wri-terraform-state"
    key          = "terraform.tfstate"
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
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    }
  }
}
