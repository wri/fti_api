terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state is local by default. To share/lock state across the team,
  # create the bucket + DynamoDB lock table once, then uncomment and `terraform init`:
  #
  # backend "s3" {
  #   bucket         = "otp-api-tfstate"
  #   key            = "production/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "otp-api-tfstate-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "otp-api"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
