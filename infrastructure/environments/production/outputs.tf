output "public_ip" {
  description = "Elastic IP of the application host. Set this as PRODUCTION_HOST."
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
  value = data.aws_vpc.default.id
}
