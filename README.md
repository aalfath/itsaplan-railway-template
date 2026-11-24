[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/its-a-plan-2?utm_medium=integration&utm_source=button&utm_campaign=itsaplan)

# It's a Plan on Railway

One-click Railway template for [It's a Plan](https://github.com/croffasia/itsaplan) **v1.12.0, Community edition (AGPL-3.0)**:
self-hosted project management (boards, timeline, cycles, docs and AI agents), a Linear and Plane alternative.

## What it deploys

| Service | Built from | What it does |
|---|---|---|
| `web` (public) | `web/` in this repo | Next.js web app, the background worker (webhooks, notifications, imports, agent schedules), the Telegram bot (idle until you add a token) and a Caddy front on `$PORT` that serves the api under `/api`. Health check `/login`. |
| `api` (private) | `api/` in this repo | Bun api. On every start it waits for Postgres, runs the database migrations (with an advisory lock) and, on the very first boot, creates the admin account and makes registration invite-only. Health check `/`. |
| `Postgres` | Railway Postgres | All app data, on a volume. |
| `Bucket` | Railway Bucket | Attachments and avatars (S3-compatible), plus a pre-migration database dump under `backups/` when an update brings migrations. |

Images are the upstream images pinned by version **and** digest in the `FROM` lines
(`ghcr.io/croffasia/itsaplan-{api,web,worker,bot}:1.12.0@sha256:…`, `caddy:2.11.9-alpine@sha256:…`).

Why the api lives under `/api` on the web domain: `*.up.railway.app` is on the Public Suffix List, so two
Railway domains cannot share a login cookie. Serving both from one host (upstream's "path on the web's host"
layout) gives a host-only, Secure `__Host-` session cookie and works on the generated Railway domain with no
custom domain.

## Variables

The only prompt is **`ADMIN_EMAIL`** (the admin's sign-in email). Everything else is set for you:

| Service | Variable | Value |
|---|---|---|
| api | `ADMIN_PASSWORD` | `${{secret(24)}}`, the admin's first password |
| api | `BETTER_AUTH_SECRET`, `APP_ENCRYPTION_KEY` | `${{secret(48)}}` |
| api | `API_URL`, `APP_URL` | `https://<web domain>/api` and `https://<web domain>` |
| api, web | `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| api, web | `S3_*` | references to the Railway Bucket |
| web | `SERVICE_URL_API` | `http://${{api.RAILWAY_PRIVATE_DOMAIN}}:${{api.PORT}}` |

## After deploy

1. Open the `api` service, **Variables**, and copy `ADMIN_PASSWORD`.
2. Open the `web` service's public URL and sign in with `ADMIN_EMAIL` and that password. Change the password under your profile.
3. The admin is the instance admin ("god mode"). Registration starts **invite-only**: invite people from a team, or open registration in god mode, Authentication.
4. Optional, in god mode: email (SMTP or Resend) for invites and password resets, Google/OIDC sign-in, the Telegram bot token, AI agent providers. Bring your own LLM key there; nothing is preset.

If you add a custom domain to `web`, change `API_URL` and `APP_URL` on `api` and `API_URL` on `web` to it and redeploy both.

Telemetry: upstream's worker sends one anonymous, content-free usage snapshot a day (see upstream `TELEMETRY.md`).
Set `TELEMETRY_DISABLED=1` on the `web` service to turn it off.

## Resources

Fits Railway's Free plan (3 services, 1 volume, 1 bucket). Tested with every service limited to 0.5 GB RAM / 1 vCPU:
`api` about 300 MB, `web` (web + worker + bot + Caddy) about 200 MB, no OOM kills. Both start scripts size thread
pools and heaps from the container's limits, and exit non-zero if any process stops, so Railway restarts the service.

## Updates

Every service except Postgres and the Bucket builds from this repo. When a new It's a Plan release is pinned here and
merged to `main`, Railway shows everyone who deployed the template an "update available" notice; read
[CHANGELOG.md](CHANGELOG.md) before applying it. Migrations run automatically on the api's next start, after a dump
of the database is copied to the bucket under `backups/`.

## Licence

It's a Plan is AGPL-3.0 (Community edition only; the Pro edition is not included). The wrapper files in this repo are
under the same licence.
