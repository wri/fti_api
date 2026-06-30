# Use the account's existing default VPC instead of creating a new one — the
# single self-hosted host needs no custom networking, and this keeps `terraform
# import` of the live box aligned with where it actually runs.
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
  source = "../../modules/storage"

  bucket_name           = var.bucket_name
  backup_retention_days = var.backup_retention_days
  cors_allowed_origins  = var.cors_allowed_origins
}

module "compute" {
  source = "../../modules/compute"

  name                     = var.name
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
