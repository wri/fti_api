# Infrastructure (Terraform)

Infrastructure-as-Code for the OTP API on AWS. This codifies the existing
single-host EC2 architecture for **staging** and **production** so the cloud
resources are reproducible and version-controlled. It deliberately does **not**
change the deploy workflow.

## What Terraform owns (and what it doesn't)

Three layers, each with one job:

| Layer | Owns | Where |
| --- | --- | --- |
| **Terraform** | Cloud resources: VPC + public subnet, EC2, Elastic IP, security group, IAM instance profile, S3 bucket, EBS snapshot policy | this directory |
| **`bin/provision`** | Host OS/software: swap, fail2ban, ufw, Postgres+PostGIS, Redis, nginx, certbot, RVM/Ruby, nvm/node, aws-cli, puma/sidekiq systemd units | repo root |
| **Capistrano** | Application deploys | `config/deploy*` |

Postgres and Redis run **self-hosted on each host** (no RDS / ElastiCache).

## Layout

```
infrastructure/
  remote-state/     # creates the S3 bucket that holds Terraform state (run once)
  modules/
    network/        # per-env VPC + single public subnet + IGW (no default VPC in this account)
    compute/        # EC2 + EIP + security group + IAM instance profile + DLM EBS snapshots
    storage/        # one S3 bucket (uploads/ + db/ prefixes) + IAM access policy
  main.tf           # module wiring — shared by all environments
  variables.tf
  outputs.tf
  versions.tf       # single S3 backend (state namespaced per workspace)
  staging.tfvars    # per-env values
  production.tfvars
```

**One root, one set of files.** Environments are **Terraform workspaces**
(`staging`, `production`), not separate directories — the workspace selects both
the state file (Terraform namespaces it automatically) and the `*.tfvars` you pass.
`terraform.workspace` drives the resource-name prefix (`otp-<workspace>`) and
the `Environment` tag, so there's nothing per-env to duplicate.

The account has **no default VPC**, so each workspace builds its own minimal
network (`modules/network`): a VPC with one public subnet routed through an
internet gateway. Pin a different subnet with `subnet_id` in the tfvars if needed.

> A guard rail (`terraform_data.workspace_guard`) refuses to run in the `default`
> workspace or any name other than `staging`/`production`, so a forgotten
> `workspace select` can't apply to the wrong environment.

## Prerequisites

- Terraform >= 1.10 (for native S3 state locking), AWS provider ~> 6.0
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
terraform apply            # creates the otp-wri-tf-state bucket
```

The bucket name/region are hard-coded in the `backend "s3"` block (`versions.tf`)
— backends can't take variables. If you change the bucket name in
`remote-state/terraform.tfvars`, update that backend block to match.

The backend is configured before the first `terraform init`, so state lives in S3
from the start — no migration needed. (Only if you had a pre-existing local
`terraform.tfstate` would you run `terraform init -migrate-state` once to lift it
up.)

## Usage

```bash
cd infrastructure
terraform init                          # configures the S3 backend

# --- staging ---
terraform workspace new staging         # first time only (then: workspace select staging)
terraform plan  -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars

# --- production ---
terraform workspace new production      # first time only
terraform workspace select production
terraform plan  -var-file=production.tfvars
terraform apply -var-file=production.tfvars
```

Always pair the selected workspace with its matching `-var-file`. The guard rail
blocks the `default` workspace, but it can't tell staging vars from production
vars — that pairing is on you.

Then wire the result into the existing deploy flow:

```bash
terraform output public_ip      # -> set as STAGING_HOST / PRODUCTION_HOST in .env.<env>
terraform output bucket_name    # -> S3 bucket for uploads + backups

ENV=staging bin/provision       # configure the host
cap staging deploy              # deploy the app
```

## Adopting the existing live servers

Production and staging already exist. Running `terraform apply` as-is creates
**parallel** infrastructure. Two options:

1. **Import (recommended for live boxes)** — adopt the running resources into
   state so Terraform manages them in place. Select the target workspace first,
   e.g.:
   ```bash
   terraform workspace select production
   terraform import -var-file=production.tfvars module.compute.aws_instance.app i-0123456789abcdef0
   terraform import -var-file=production.tfvars module.compute.aws_eip.app eipalloc-0123456789abcdef0
   # if the live host sits in an existing VPC, import that too (module.network.aws_vpc.main
   # etc.) or set subnet_id in the tfvars and remove the network module for that env
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
- **DB backups** — the host-side `aws s3 sync` cron (set up by `bin/provision`)
  targets `s3://otp-wri-<env>/db/`. Retention/pruning of current objects is
  handled host-side by the backup script; a bucket lifecycle rule expires
  noncurrent versions after 30 days so `sync --delete` churn doesn't accumulate.

## Backups & snapshots

- **EBS snapshots** — Data Lifecycle Manager snapshots the host's root volume
  daily, retaining `snapshot_retain_count` (prod 14). Staging sets
  `enable_snapshots = false`, which keeps the DLM policy but in `DISABLED` state.
  The volume is tagged `Snapshot = otp-<env>` and each env's DLM policy targets
  only that value (DLM matches account+region-wide, so a shared tag would
  cross-snapshot both envs). Block-level protection for the self-hosted Postgres
  data.
- **Logical DB dumps** — the `aws s3 sync` cron under `db/`. The two are
  complementary.

## Notes

- The security group (edge firewall) and host `ufw` both gate 22/80/443 — keep
  them in sync if you change ports.
- `ssh_allowed_cidrs` defaults to `0.0.0.0/0` in the tfvars — **narrow it** to
  known admin IPs.
- Remote state is an S3 bucket with native locking (no DynamoDB) — see
  [Remote state](#remote-state-one-time-setup).
- The instance ignores AMI changes (`lifecycle.ignore_changes = [ami]`) so a new
  Ubuntu release won't trigger a host rebuild.
