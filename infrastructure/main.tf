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

# Per-environment network. This account has no default VPC, so each workspace
# builds its own VPC + public subnet (otp-staging / otp-production).
module "network" {
  source = "./modules/network"

  name = local.name
}

module "storage" {
  source = "./modules/storage"

  bucket_name = var.bucket_name
}

module "compute" {
  source = "./modules/compute"

  name                     = local.name
  vpc_id                   = module.network.vpc_id
  subnet_id                = var.subnet_id != "" ? var.subnet_id : module.network.subnet_id
  instance_type            = var.instance_type
  ami_id                   = var.ami_id
  key_name                 = var.key_name
  ssh_allowed_cidrs        = var.ssh_allowed_cidrs
  root_volume_size         = var.root_volume_size
  bucket_access_policy_arn = module.storage.access_policy_arn
  snapshot_retain_count    = var.snapshot_retain_count
}
