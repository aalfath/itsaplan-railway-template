# It's a Plan web (Next.js) + background worker + Telegram bot + Caddy front, Community edition (AGPL-3.0), v1.12.0.
FROM ghcr.io/croffasia/itsaplan-worker:1.12.0@sha256:5ae5d1123f3dc9f366b1516d110a043f9caa60fcb043a54abc9f99ab0be3d200 AS worker
FROM ghcr.io/croffasia/itsaplan-bot:1.12.0@sha256:a3f5a1518a5194ccbd37ca014b2fd00e6c76a120582d4feec554829fa883d70a AS bot
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

FROM ghcr.io/croffasia/itsaplan-web:1.12.0@sha256:95d4a9253608a00e2e6b82c68f92dd7e24bbf86bca537d66b8868c3a12926e24
# The worker (webhooks, notifications, imports, agent schedules) and the Telegram bot
# (idle until a bot token is saved in god mode) run in this service beside the web app, so the whole stack fits Railway's Free plan (3 services).
COPY --from=worker /usr/local/bin/bun /usr/local/bin/bun
COPY --from=worker /app /worker
COPY --from=bot /app /bot
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile start.sh /opt/railway/
RUN chmod 755 /opt/railway/start.sh && /usr/local/bin/bun --version && caddy version

ENV BUILD_NAME=community
CMD ["/bin/sh", "/opt/railway/start.sh"]
