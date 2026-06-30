output "public_ip" {
  description = "Elastic IP of the application host. Set this as STAGING_HOST."
  value       = module.compute.public_ip
}

output "instance_id" {
  value = module.compute.instance_id
}

output "bucket_name" {
  description = "S3 bucket for uploads (and db-backups, unused on staging)."
  value       = module.storage.bucket_name
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}
