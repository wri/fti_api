region      = "us-east-1"
environment = "production"
name        = "OTP Production"

instance_type = "t4g.large"

# Optional: pin a specific subnet. Empty uses the first default-VPC subnet.
# subnet_id = "subnet-0123456789abcdef0"

# An existing EC2 key pair name in the target region.
# key_name = "otp-api"

# Lock SSH down to known admin IPs. 0.0.0.0/0 is open to the world — narrow it.
ssh_allowed_cidrs = ["0.0.0.0/0"]

root_volume_size = 100

bucket_name           = "otp-wri-production"
backup_retention_days = 30
snapshot_retain_count = 14

# e.g. ["https://opentimberportal.org"]
cors_allowed_origins = []
