output "public_ip" {
  description = "Elastic IP of the host. Set this as STAGING_HOST / PRODUCTION_HOST."
  value       = module.compute.public_ip
}

output "instance_id" {
  value = module.compute.instance_id
}

output "bucket_name" {
  description = "S3 bucket for uploads (uploads/) and db-backups (db-backups/)."
  value       = module.storage.bucket_name
}

output "vpc_id" {
  value = module.network.vpc_id
}
