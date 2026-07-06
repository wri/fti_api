data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-*-26.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# Security group: edge-level firewall. Mirrors the host-level ufw rules from
# bin/provision (22/80/443). Keep the two in sync. Postgres/Redis are
# loopback-only on the host, so no DB/cache ingress is exposed here.
# -----------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "Application host: SSH + HTTP/HTTPS."
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-app"
  })
}

# -----------------------------------------------------------------------------
# Instance profile: lets the host use S3 (Active Storage + aws-cli backup cron)
# via an IAM role instead of static AWS keys.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.name}-app"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "bucket_access" {
  role       = aws_iam_role.app.name
  policy_arn = var.bucket_access_policy_arn
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app"
  role = aws_iam_role.app.name
  tags = var.tags
}

# -----------------------------------------------------------------------------
# Application host. Bootstrapping is intentionally left to bin/provision; this
# only creates the bare instance.
# -----------------------------------------------------------------------------
resource "aws_instance" "app" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.app.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(var.tags, {
      Name     = "${var.name}-root"
      Snapshot = "true"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.name}-app"
  })

  lifecycle {
    # The AMI updates over time; don't recreate a live host on a new AMI release.
    ignore_changes = [ami]
  }
}

# Stable public IP, matching the current fixed-IP hosts.
resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app.id

  tags = merge(var.tags, {
    Name = "${var.name}-eip"
  })
}

# -----------------------------------------------------------------------------
# Automated EBS snapshots via Data Lifecycle Manager. Targets volumes tagged
# Snapshot=true (the host's root volume).
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "dlm_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm" {
  name               = "${var.name}-dlm"
  assume_role_policy = data.aws_iam_policy_document.dlm_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "ebs" {
  description        = "${var.name} automated EBS snapshots"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    target_tags = {
      Snapshot = "true"
    }

    schedule {
      name = "${var.name}-daily"

      create_rule {
        interval      = var.snapshot_interval_hours
        interval_unit = "HOURS"
        times         = [var.snapshot_start_time]
      }

      retain_rule {
        count = var.snapshot_retain_count
      }

      tags_to_add = merge(var.tags, {
        SnapshotCreator = "dlm"
      })

      copy_tags = true
    }
  }

  tags = var.tags
}
