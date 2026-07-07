# Infrastructure (Terraform)

Infrastructure-as-Code for the OTP API on AWS. This codifies the existing
single-host EC2 architecture for **staging** and **production** so the cloud
resources are reproducible and version-controlled. It deliberately does **not**
change the deploy workflow.

## What Terraform owns (and what it doesn't)

Three layers, each with one job:

| Layer | Owns | Where |
| --- | --- | --- |
| **Terraform** | Cloud resources: EC2, Elastic IP, security group, IAM instance profile, S3 bucket, EBS snapshot policy | this directory |
| **`bin/provision`** | Host OS/software: swap, fail2ban, ufw, Postgres+PostGIS, Redis, nginx, certbot, RVM/Ruby, nvm/node, aws-cli, puma/sidekiq systemd units | repo root |
| **Capistrano** | Application deploys | `config/deploy*` |

Postgres and Redis run **self-hosted on each host** (no RDS / ElastiCache).

## Layout

```
infrastructure/
  remote-state/  # creates the S3 bucket that holds Terraform state (run once)
  modules/
    compute/   # EC2 + EIP + security group + IAM instance profile + DLM EBS snapshots
    storage/   # one S3 bucket (uploads/ + db-backups/ prefixes) + IAM access policy
  environments/
    staging/      # t4g.small
    production/   # t4g.large
```

Each `environments/<env>/` is an independent Terraform root with its own state.
The host launches into the account's **default VPC** (looked up via data source);
no custom VPC is created. Pin a specific subnet with `subnet_id` in `terraform.tfvars`
if you don't want the first default-VPC subnet.

## Prerequisites

- Terraform >= 1.5, AWS provider ~> 5.0
- AWS credentials with permission to manage VPC/EC2/IAM/S3/DLM (e.g. `AWS_PROFILE`)
- An existing EC2 **key pair** in the target region; put its name in
  `terraform.tfvars` (`key_name`)

## Remote state (one-time setup)

State lives in a dedicated, versioned, encrypted S3 bucket with **native S3
locking** (`use_lockfile`). One state file per environment (`staging/…`, `production/…`).

The bucket must exist before the env backends can use it, so create it once with
the `remote-state/` config (which keeps its own state local by design):

```bash
cd infrastructure/remote-state
terraform init
terraform apply            # creates the otp-terraform-state bucket
```

The bucket name/region are hard-coded in each env's `backend "s3"` block
(`versions.tf`) — backends can't take variables. If you change the bucket name in
`remote-state/terraform.tfvars`, update those two backend blocks to match.

Then, in each environment, migrate the existing local state up:

```bash
cd infrastructure/environments/staging
terraform init -migrate-state   # answer "yes" to copy local state to S3
```

## Usage

```bash
cd infrastructure/environments/staging   # or production

terraform init
terraform plan
terraform apply
```

Then wire the result into the existing deploy flow:

```bash
terraform output public_ip     # -> set as STAGING_HOST / PRODUCTION_HOST in .env.<env>
terraform output bucket_name    # -> S3 bucket for uploads + backups

ENV=staging bin/provision        # configure the host
cap staging deploy               # deploy the app
```

## Adopting the existing live servers

Production and staging already exist. Running `terraform apply` as-is creates
**parallel** infrastructure. Two options:

1. **Import (recommended for live boxes)** — adopt the running resources into
   state so Terraform manages them in place, e.g.:
   ```bash
   terraform import module.compute.aws_instance.app i-0123456789abcdef0
   terraform import module.compute.aws_eip.app eipalloc-0123456789abcdef0
   # the default VPC/subnet are read-only data sources, so nothing to import there
   ```
   Run `terraform plan` afterwards and reconcile `terraform.tfvars` until the plan
   shows **no destructive changes**.
2. **Greenfield** — apply fresh, then cut over DNS and Capistrano to the new EIP.

## Wiring the S3 bucket into the app

The bucket is created but the app must opt in:

- **Uploads** — enable the `amazon:` service in `config/storage.yml` (the S3 stub
  is already there) and point Active Storage / CarrierWave at the bucket's
  `uploads/` prefix. The host uses its instance-profile IAM role, so **no static
  AWS keys** are required.
- **DB backups** — the host-side `aws s3 sync` cron should target
  `s3://otp-api-production/db-backups/` (production only). Objects under that
  prefix expire per `backup_retention_days`.

## Backups & snapshots

- **EBS snapshots** — Data Lifecycle Manager snapshots the host's root volume
  (tagged `Snapshot = true`) daily, retaining `snapshot_retain_count`
  (prod 14 / staging 7). Block-level protection for the self-hosted Postgres data.
- **Logical DB dumps** — the existing `aws s3 sync` cron under `db-backups/`
  (production). The two are complementary.

## Notes

- The security group (edge firewall) and host `ufw` both gate 22/80/443 — keep
  them in sync if you change ports.
- `ssh_allowed_cidrs` defaults to `0.0.0.0/0` in the tfvars — **narrow it** to
  known admin IPs.
- Remote state is an S3 bucket with native locking (no DynamoDB) — see
  [Remote state](#remote-state-one-time-setup).
- The instance ignores AMI changes (`lifecycle.ignore_changes = [ami]`) so a new
  Ubuntu release won't trigger a host rebuild.
