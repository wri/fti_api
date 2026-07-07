locals {
  # The workspace IS the environment. Derive a clean resource-name prefix from it.
  name = "otp-${terraform.workspace}"
}

# Guard rail: refuse to run in the `default` workspace or any unexpected one, so a
# forgotten `terraform workspace select` can't apply to the wrong environment.
resource "terraform_data" "workspace_guard" {
  lifecycle {
    precondition {
      condition     = contains(["staging", "production"], terraform.workspace)
      error_message = "Select an environment first: `terraform workspace select staging|production`. Refusing to run in workspace '${terraform.workspace}'."
    }
  }
}

# Existing default VPC — no custom networking for a single self-hosted host.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "storage" {
  source = "./modules/storage"

  bucket_name = var.bucket_name
}

module "compute" {
  source = "./modules/compute"

  name                     = local.name
  vpc_id                   = data.aws_vpc.default.id
  subnet_id                = var.subnet_id != "" ? var.subnet_id : tolist(data.aws_subnets.default.ids)[0]
  instance_type            = var.instance_type
  ami_id                   = var.ami_id
  key_name                 = var.key_name
  ssh_allowed_cidrs        = var.ssh_allowed_cidrs
  root_volume_size         = var.root_volume_size
  bucket_access_policy_arn = module.storage.access_policy_arn
  snapshot_retain_count    = var.snapshot_retain_count
}
