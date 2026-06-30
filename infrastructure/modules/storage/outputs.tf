output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "access_policy_arn" {
  description = "ARN of the IAM policy granting the host access to the bucket."
  value       = aws_iam_policy.bucket_access.arn
}
