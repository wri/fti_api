# Single bucket per environment: a backup target fed by host-side `aws s3 sync`
# cron jobs (bin/provision), via two key prefixes:
#   db/      -> nightly database dumps
#   uploads/ -> hourly mirror of local CarrierWave uploads (app serves from disk)
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Expire noncurrent versions so daily `sync --delete` churn doesn't accumulate.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Enable intelligent tiering for all objects, so that infrequently accessed files are automatically moved to a cheaper storage class.
  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    filter {}

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM policy granting the application host read/write access to this bucket.
# Consumed by the compute module's instance role -> no static AWS keys on the host.
data "aws_iam_policy_document" "bucket_access" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.this.arn]
  }

  statement {
    sid    = "ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_iam_policy" "bucket_access" {
  name        = "${var.bucket_name}-access"
  description = "Read/write access to the ${var.bucket_name} bucket for the application host."
  policy      = data.aws_iam_policy_document.bucket_access.json
}
