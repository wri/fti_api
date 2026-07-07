region        = "eu-central-1"
instance_type = "t4g.small"

# An existing EC2 key pair name in eu-central-1.
# key_name = "otp-api"

# Lock SSH down to known admin IPs. 0.0.0.0/0 is open to the world — narrow it.
ssh_allowed_cidrs = ["0.0.0.0/0"]

# Optional: pin a specific subnet. Empty uses the first default-VPC subnet.
# subnet_id = "subnet-0123456789abcdef0"

root_volume_size = 100

bucket_name           = "otp-wri-staging"
backup_retention_days = 14
snapshot_retain_count = 7

# e.g. ["https://staging.opentimberportal.org"]
cors_allowed_origins = []
