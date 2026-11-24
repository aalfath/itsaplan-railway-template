#!/bin/sh
# Start script for the It's a Plan api on Railway.
# 1. wait for Postgres, 2. migrate (pre-migration dump copied to the bucket),
# 3. start the api, 4. create the admin account on first boot.
# Any failure, or an unexpected stop of the api, exits non-zero so Railway restarts it.
set -u

export API_PORT="${PORT:-3000}"
export NODE_ENV=production
# Railway's edge writes the client address into X-Real-IP; the sign-in rate limit keys on it.
export CLIENT_IP_HEADER="${CLIENT_IP_HEADER:-x-real-ip}"
export BACKUP_DIR="${BACKUP_DIR:-/tmp/itsaplan-backups}"

for v in DATABASE_URL BETTER_AUTH_SECRET APP_ENCRYPTION_KEY API_URL APP_URL; do
  eval "val=\${$v:-}"
  if [ -z "$val" ]; then echo "[railway] $v is not set" >&2; exit 1; fi
done

echo "[railway] waiting for Postgres"
i=0
until psql "$DATABASE_URL" -qtAc 'select 1' >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -ge 90 ]; then echo "[railway] Postgres did not answer in 180 s" >&2; exit 1; fi
  sleep 2
done

cd /app
bun run packages/db/src/migrate.ts
rc=$?
# A dump is only written when a release brings migrations to an existing database.
if ls "$BACKUP_DIR"/*.dump >/dev/null 2>&1; then
  bun /opt/railway/upload-backups.ts || echo "[railway] could not copy the pre-migration dump to the bucket" >&2
fi
if [ "$rc" -ne 0 ]; then echo "[railway] migrations failed ($rc)" >&2; exit 1; fi

bun run apps/api/src/index.ts &
api=$!
trap 'kill -TERM "$api" 2>/dev/null; wait "$api"; exit 0' TERM INT

# First boot: the first account becomes the instance admin ("god"), so create it here
# from the generated ADMIN_PASSWORD instead of leaving sign-up open to the first visitor.
users=$(psql "$DATABASE_URL" -qtAc 'select count(*) from "user"' 2>/dev/null || echo "?")
if [ "$users" = "0" ]; then
  bun /opt/railway/bootstrap-admin.ts || echo "[railway] admin bootstrap failed; see above" >&2
fi

wait "$api"
rc=$?
echo "[railway] api exited with $rc" >&2
[ "$rc" -eq 0 ] && rc=1
exit "$rc"
