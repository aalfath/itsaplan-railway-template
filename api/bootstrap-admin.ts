// First-boot admin for It's a Plan on Railway. Runs only while the instance has no
// account. Signs up ADMIN_EMAIL with ADMIN_PASSWORD through the api's own sign-up route,
// so the account becomes "god" (instance admin), then makes registration invite-only.
import { $ } from 'bun';

const port = process.env.API_PORT || '3000';
const base = `http://127.0.0.1:${port}`;
const email = (process.env.ADMIN_EMAIL || 'admin@example.com').trim();
const password = process.env.ADMIN_PASSWORD || '';
const origin = (process.env.APP_URL || '').split(',')[0].trim().replace(/\/+$/, '');

if (password.length < 8) {
  console.error('[railway] ADMIN_PASSWORD is missing or shorter than 8 characters; no admin created');
  process.exit(1);
}

for (let i = 0; i < 60; i++) {
  try {
    if ((await fetch(`${base}/`)).ok) break;
  } catch {}
  await Bun.sleep(1000);
}

const res = await fetch(`${base}/api/auth/sign-up/email`, {
  method: 'POST',
  headers: { 'content-type': 'application/json', origin },
  body: JSON.stringify({ email, password, name: 'Admin' }),
});
if (!res.ok) {
  console.error(`[railway] admin sign-up answered ${res.status}: ${(await res.text()).slice(0, 300)}`);
  process.exit(1);
}

// Invite-only from now on; the admin can open registration in god mode, Authentication.
const url = process.env.DATABASE_URL!;
await $`psql ${url} -qtAc ${`insert into app_setting (key, value) values ('auth', '{"registration":"invite"}'::jsonb) on conflict (key) do update set value = app_setting.value || '{"registration":"invite"}'::jsonb, updated_at = now()`}`.quiet();
console.log(`[railway] admin account ${email} created; registration set to invite-only`);
