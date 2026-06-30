output "public_ip" {
  description = "Elastic IP address of the application host."
  value       = aws_eip.app.public_ip
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.app.id
}

output "instance_role_arn" {
  description = "ARN of the host's IAM role."
  value       = aws_iam_role.app.arn
}

output "security_group_id" {
  description = "ID of the application security group."
  value       = aws_security_group.app.id
}
