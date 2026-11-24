// Copies the dump upstream's migrate step writes before applying a release's migrations
// into the Railway bucket (backups/), because the api container has no volume of its own.
import { readdir, unlink } from 'node:fs/promises';
import { join } from 'node:path';

const dir = process.env.BACKUP_DIR || '/tmp/itsaplan-backups';
const { S3_ENDPOINT, S3_BUCKET, S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY } = process.env;
if (!S3_ENDPOINT || !S3_BUCKET || !S3_ACCESS_KEY_ID || !S3_SECRET_ACCESS_KEY) {
  console.error('[railway] bucket not configured; pre-migration dump stays in the container only');
  process.exit(1);
}
const client = new Bun.S3Client({
  endpoint: S3_ENDPOINT,
  bucket: S3_BUCKET,
  accessKeyId: S3_ACCESS_KEY_ID,
  secretAccessKey: S3_SECRET_ACCESS_KEY,
  region: process.env.S3_REGION || 'us-east-1',
  virtualHostedStyle: process.env.S3_FORCE_PATH_STYLE === 'false',
});
for (const name of await readdir(dir)) {
  if (!name.endsWith('.dump')) continue;
  const path = join(dir, name);
  await client.write(`backups/${name}`, Bun.file(path));
  await unlink(path);
  console.log(`[railway] pre-migration dump copied to the bucket: backups/${name}`);
}
