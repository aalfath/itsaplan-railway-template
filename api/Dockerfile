# It's a Plan api (Community edition, AGPL-3.0), upstream release v1.12.0.
FROM ghcr.io/croffasia/itsaplan-api:1.12.0@sha256:b46a6c56396b3e57eda3a56eb625da310e1ff55a65fce9abd6f36ae6d2479113

COPY start.sh upload-backups.ts bootstrap-admin.ts /opt/railway/
RUN chmod 755 /opt/railway/start.sh

EXPOSE 3000
CMD ["/bin/sh", "/opt/railway/start.sh"]
