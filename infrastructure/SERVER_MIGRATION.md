# Server migration runbook

Moving an environment (staging or production) to a new EC2 host with minimal
downtime. The flow: build and fully test the new server while DNS still points at
the old one, issue the real TLS certificate through an ACME proxy on the old
server, then cut over behind a short maintenance window.

Placeholders used below:

- `<NEW_IP>` — Elastic IP of the new server (`terraform output public_ip`)
- `<USER>` — the deploy user (`SSH_USER` in `.env`)

> **Production only:** `PRODUCTION_HOST` is both the sync **source** (`bin/sync`
> pulls from it) and the deploy **target** (Capistrano/provision push to it). It
> must keep pointing at the **old** server until the final sync, which is why the
> production commands below target the new box with a per-command
> `PRODUCTION_HOST=<NEW_IP>` override. Flip it in `.env` only after cutover. For
> staging there is no conflict — set `STAGING_HOST=<NEW_IP>` in `.env` right away.

## Phase 1 — Build the new server

1. Create the infrastructure (see [README](./README.md) for the workspace setup):

2. Leave `STAGING_DOMAIN` / `PRODUCTION_DOMAIN` **unset** for now — DNS still
   points at the old server, so provisioning issues a self-signed cert for the
   bare IP instead of trying Let's Encrypt.

3. Add the new host key unhashed, otherwise Capistrano fails with
   `HostKeyMismatch` (net-ssh can't read hashed `known_hosts` entries):

   ```bash
   ssh-keyscan <NEW_IP> >> ~/.ssh/known_hosts
   ```

4. Provision (needs `SSH_USER`, `LETSENCRYPT_EMAIL` and, on staging,
   `AUTH_BASIC_PASSWORD` in `.env`; basic auth is off by default in production;

   ```bash
   # staging
   ENV=staging bin/provision

   # production
   ENV=production PRODUCTION_HOST=<NEW_IP> bin/provision
   ```

## Phase 2 — Seed data and deploy

Both sync commands stream from the production server directly to the target. A
raw-IP target restores into `fti_api_production`; `bin/sync` refuses the
`production` alias as a target on purpose:

```bash
# staging
bin/sync db staging
bin/sync files staging

# production
bin/sync db <NEW_IP>
bin/sync files <NEW_IP>
```

Deploy the API:

```bash
# staging
cap staging deploy

# production
PRODUCTION_HOST=<NEW_IP> cap production deploy
```

> **Production only:** after this deploy the new server runs Sidekiq and the app
> cron jobs against a copy of the live DB — scheduled emails could go out twice.
> Either deploy with `SKIP_CRON=true` and stop Sidekiq on the new box until
> cutover, or migrate outside the schedule of jobs that notify users.

Deploy the frontends. Provisioning created bare repos with a `post-receive` hook
that checks out the pushed branch and runs `script/deploy <env>`, so a push is a
deploy — copy each app's server-side env config from the old server **first**
(portal: `/var/www/otp-portal/.env`, observations tool likewise), with API URLs
pointed at `https://<NEW_IP>` for testing.

In each frontend repo (otp-portal, otp-observations-tool):

```bash
git remote add new-server <USER>@<NEW_IP>:git/otp-portal.git   # or otp-observations-tool.git

# staging
git push new-server staging

# production
git push new-server master
```

**Test everything against `https://<NEW_IP>`** (accept the self-signed cert). API,
admin, portal, observations tool, Sidekiq (`systemctl status sidekiq`), cron lists.

## Phase 3 — Issue the real certificate

DNS still points at the old server, so Let's Encrypt's HTTP-01 challenge lands
there. Forward just the challenge path to the new box: on the **old** server, add
to the SSL `server` block of `/etc/nginx/sites-available/otp.conf` and reload
nginx:

```nginx
  location ^~ /.well-known/acme-challenge/ {
    auth_basic off;
    proxy_pass http://<NEW_IP>;
  }
```

Now set the real domain(s) in `.env`:

```bash
STAGING_DOMAIN=staging.opentimberportal.org
PRODUCTION_DOMAIN=opentimberportal.org,www.opentimberportal.org,opentimberportal.com,www.opentimberportal.com,opentimberportal.net,www.opentimberportal.net
```

Then re-run provisioning — this rewrites nginx for the domain and issues the
certificate on the new server:

```bash
# staging
ENV=staging bin/provision

# production
ENV=production PRODUCTION_HOST=<NEW_IP> bin/provision
```

Now, on the new server, point the frontend `.env` API URLs back at the real domain
and redeploy both apps from their checkouts:

```bash
# in /var/www/otp-portal and /var/www/otp-observations-tool

# staging
script/deploy staging

# production
script/deploy production
```

## Phase 4 — Cutover

Downtime starts at step 3 and ends at step 5.

1. Put the **new** server in maintenance mode, so anything arriving during the
   final sync sees the maintenance page:

   ```bash
   # staging
   cap staging maintenance:enable

   # production
   PRODUCTION_HOST=<NEW_IP> cap production maintenance:enable
   ```

2. Freeze the **old** server — stop background processing and cron so nothing
   writes to the old DB after the final sync:

   ```bash
   crontab -l > cronbackup.txt && crontab -r     # restore with: crontab cronbackup.txt
   sudo systemctl stop sidekiq puma
   ```

3. Turn the old server into a TCP proxy for the new one, so traffic works during
   DNS propagation. On the **old** server (stream is a top-level context — put
   this in `/etc/nginx/nginx.conf`, not inside `http {}`; install
   `libnginx-mod-stream` if missing):

   ```nginx
   stream {
     server {
       listen 443;
       proxy_pass <NEW_IP>:443;
     }
     server {
       listen 80;
       proxy_pass <NEW_IP>:80;
     }
   }
   ```

   The site config holds ports 80/443, so disable it in the same step:

   ```bash
   sudo rm -f /etc/nginx/sites-enabled/otp.conf
   sudo systemctl restart nginx
   ```

   Check that the domain now serves the maintenance page. To roll back:

   ```bash
   # remove the stream block, then
   sudo ln -sf /etc/nginx/sites-available/otp.conf /etc/nginx/sites-enabled/otp.conf
   sudo systemctl restart nginx
   ```

4. Final sync of everything written since Phase 2:

   ```bash
   # staging
   bin/sync db staging
   bin/sync files staging

   # production
   bin/sync db <NEW_IP>
   bin/sync files <NEW_IP>
   ```

5. Bring the new server live:

   ```bash
   # staging
   cap staging maintenance:disable

   # production
   PRODUCTION_HOST=<NEW_IP> cap production maintenance:disable
   ```

   The site is up again — served by the new box through the old box's proxy.

6. Update the DNS A record(s) to `<NEW_IP>` and set `STAGING_HOST` /
   `PRODUCTION_HOST` to `<NEW_IP>` in `.env` (overrides no longer needed).

## Phase 5 — Decommission

Once DNS has propagated (old server's nginx access log goes quiet):

- stop the old instance; leave it stopped for a grace period before terminating
  (production may have termination protection — take a last EBS snapshot before
  terminating anyway)
- remove the temporary `new-server` git remotes locally, or rename them
