region        = "us-east-1"
instance_type = "t4g.large"

# An existing EC2 key pair name in us-east-1.
# key_name = "otp-api"

# Lock SSH down to known admin IPs. 0.0.0.0/0 is open to the world — narrow it.
ssh_allowed_cidrs = ["0.0.0.0/0"]

# Optional: pin a specific subnet. Empty uses the first default-VPC subnet.
# subnet_id = "subnet-0123456789abcdef0"

root_volume_size = 100

bucket_name           = "otp-wri-production"
snapshot_retain_count = 14
