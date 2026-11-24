# Changelog

Breaking changes are listed first in each entry. Railway shows an "update available"
notice for every merge to `main`; read the entry before you apply it.

## v1.12.0-railway.1 (2026-11-24)

- First release of the template: It's a Plan v1.12.0 Community edition (AGPL-3.0).
- Services: `api` (Bun api, migrations and first-boot admin), `web` (Next.js web app,
  background worker, Telegram bot and a Caddy front that serves the api under `/api`), Railway Postgres
  with a volume, and a Railway Bucket for attachments.
- Images pinned by version and digest:
  - `ghcr.io/croffasia/itsaplan-api:1.12.0@sha256:b46a6c56396b3e57eda3a56eb625da310e1ff55a65fce9abd6f36ae6d2479113`
  - `ghcr.io/croffasia/itsaplan-web:1.12.0@sha256:95d4a9253608a00e2e6b82c68f92dd7e24bbf86bca537d66b8868c3a12926e24`
  - `ghcr.io/croffasia/itsaplan-bot:1.12.0@sha256:a3f5a1518a5194ccbd37ca014b2fd00e6c76a120582d4feec554829fa883d70a`
  - `ghcr.io/croffasia/itsaplan-worker:1.12.0@sha256:5ae5d1123f3dc9f366b1516d110a043f9caa60fcb043a54abc9f99ab0be3d200`
  - `caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0`
- First boot creates the admin from `ADMIN_EMAIL` and a generated `ADMIN_PASSWORD` and makes registration
  invite-only; if that fails the api stops and Railway retries, so sign-up is never left open.
