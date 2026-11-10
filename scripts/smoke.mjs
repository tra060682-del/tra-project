const raw = process.env.SMOKE_BASE_URL;
if (!raw) throw new Error('SMOKE_BASE_URL is required');
const base = new URL(raw);
const isLocal = ['127.0.0.1', 'localhost'].includes(base.hostname);
const isApprovedHost = base.protocol === 'https:' && (base.hostname === 'therealart.in' || base.hostname.endsWith('.netlify.app'));
if (!isLocal && !isApprovedHost) throw new Error('Refusing to smoke-test an unapproved host');

const checks = [
  ['homepage', '/', [200]],
  ['catalogue', '/artworks', [200]],
  ['artist registration', '/join-as-artist', [200]],
  ['login', '/login', [200]],
  ['password recovery', '/forgot-password', [200]],
  ['admin restriction', '/admin', [302, 303, 307, 308]],
];
let failures = 0;
for (const [name, path, allowed] of checks) {
  const response = await fetch(new URL(path, base), {redirect: 'manual'});
  const location = response.headers.get('location') || '';
  const adminSafe = name !== 'admin restriction' || /\/(login|access-denied)/.test(location);
  const pass = allowed.includes(response.status) && adminSafe;
  console.log(`${pass ? 'PASS' : 'FAIL'} ${name}: HTTP ${response.status}`);
  if (!pass) failures++;
}
const api = await fetch(new URL('/api/bids', base), {
  method: 'POST', headers: {'content-type': 'application/json', origin: 'https://invalid.example'}, body: '{}', redirect: 'manual',
});
const apiPass = api.status === 403;
console.log(`${apiPass ? 'PASS' : 'FAIL'} critical API origin restriction: HTTP ${api.status}`);
if (!apiPass) failures++;
if (failures) process.exit(1);
