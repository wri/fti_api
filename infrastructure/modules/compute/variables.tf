variable "name" {
  description = "Name prefix for compute resources (e.g. otp-staging)."
  type        = string
}

variable "vpc_id" {
  description = "VPC the host is launched into."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet the host is launched into."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (e.g. t3.small for staging, t3.large for production)."
  type        = string
}

variable "ami_id" {
  description = "AMI override. Empty uses the latest Ubuntu 26.04 LTS."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to reach SSH (port 22)."
  type        = list(string)
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 100
}

variable "bucket_access_policy_arn" {
  description = "IAM policy ARN (from the storage module) granting S3 access."
  type        = string
}

variable "snapshot_retain_count" {
  description = "Number of EBS snapshots to retain."
  type        = number
  default     = 7
}
