output "bucket_name" {
  description = "Name of the Terraform state bucket. Use this as `bucket` in each env's backend block."
  value       = aws_s3_bucket.state.id
}

output "region" {
  description = "Region of the state bucket. Use this as `region` in each env's backend block."
  value       = var.region
}
