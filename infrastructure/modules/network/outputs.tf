output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet the host is launched into."
  value       = aws_subnet.public.id
}
