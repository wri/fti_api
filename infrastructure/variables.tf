variable "region" {
  description = "AWS region for this environment's resources."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. Architecture (x86/ARM) is auto-detected for the AMI."
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access (region-scoped)."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to reach SSH (port 22)."
  type        = list(string)
}

variable "ami_id" {
  description = "AMI override. Empty uses the latest Ubuntu 26.04 LTS for the instance's architecture."
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet to launch the host into. Empty uses the public subnet from the network module."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 100
}

variable "bucket_name" {
  description = "S3 bucket name for uploads + db-backups (globally unique)."
  type        = string
}

variable "snapshot_retain_count" {
  description = "Number of automated EBS snapshots to retain."
  type        = number
  default     = 7
}
