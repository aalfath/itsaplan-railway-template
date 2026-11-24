#!/bin/sh
# Start script for the It's a Plan web service on Railway: Next.js web app on 127.0.0.1:3001,
# the background worker, the Telegram bot, and Caddy on $PORT in front. If any of them stops, the others
# are stopped and the script exits non-zero so Railway restarts the service.
set -u

for v in API_URL SERVICE_URL_API DATABASE_URL APP_ENCRYPTION_KEY; do
  eval "val=\${$v:-}"
  if [ -z "$val" ]; then echo "[railway] $v is not set" >&2; exit 1; fi
done

# Railway shows the host's CPUs inside a 1 vCPU service: size thread pools from the cgroup.
cpus=1
if [ -r /sys/fs/cgroup/cpu.max ]; then
  read -r q p < /sys/fs/cgroup/cpu.max
  if [ "$q" != "max" ] && [ "${p:-0}" -gt 0 ]; then cpus=$(( (q + p - 1) / p )); fi
fi
[ "$cpus" -lt 1 ] && cpus=1
[ "$cpus" -gt 4 ] && cpus=4
export GOMAXPROCS="$cpus" UV_THREADPOOL_SIZE="${UV_THREADPOOL_SIZE:-$cpus}" VIPS_CONCURRENCY="${VIPS_CONCURRENCY:-1}"
export NODE_ENV=production NEXT_TELEMETRY_DISABLED=1
export API_UPSTREAM="${SERVICE_URL_API#http://}"
export PORT="${PORT:-8080}"

# Heap caps from the memory limit (web gets about 40 %, the worker runs with --smol).
mem=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
if [ "$mem" != "max" ]; then
  heap=$(( mem / 1048576 * 40 / 100 ))
  [ "$heap" -lt 128 ] && heap=128
  [ "$heap" -gt 1024 ] && heap=1024
  export NODE_OPTIONS="${NODE_OPTIONS:-} --max-old-space-size=$heap"
fi

cd /app
PORT=3001 HOSTNAME=127.0.0.1 node apps/web/server.js &
web=$!
(cd /worker && exec bun --smol run apps/worker/src/index.ts) &
worker=$!
(cd /bot && exec bun --smol run apps/bot/src/index.ts) &
bot=$!
caddy run --config /opt/railway/Caddyfile --adapter caddyfile &
proxy=$!

stop() { kill -TERM "$web" "$worker" "$bot" "$proxy" 2>/dev/null; }
trap 'stop; wait; exit 0' TERM INT

# BusyBox `wait -n` doesn't return on the first child exit, so poll.
while kill -0 "$web" 2>/dev/null && kill -0 "$worker" 2>/dev/null && kill -0 "$bot" 2>/dev/null && kill -0 "$proxy" 2>/dev/null; do
  sleep 2
done
for n in web worker bot proxy; do
  eval "pid=\$$n"
  kill -0 "$pid" 2>/dev/null || echo "[railway] $n stopped" >&2
done
stop
wait
exit 1
