variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "staging"
}

variable "name" {
  description = "Resource name prefix."
  type        = string
  default     = "otp-api-staging"
}

variable "subnet_id" {
  description = "Subnet to launch the host into. Empty picks the first default-VPC subnet."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for the application host."
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to reach SSH."
  type        = list(string)
}

variable "ami_id" {
  description = "AMI override. Empty uses the latest Ubuntu 26.04 LTS."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 100
}

variable "bucket_name" {
  description = "S3 bucket name for uploads + db-backups."
  type        = string
}

variable "backup_retention_days" {
  description = "Retention for objects under db-backups/."
  type        = number
  default     = 30
}

variable "cors_allowed_origins" {
  description = "Origins allowed for direct browser access to the bucket."
  type        = list(string)
  default     = []
}

variable "snapshot_retain_count" {
  description = "Number of automated EBS snapshots to retain."
  type        = number
  default     = 7
}
