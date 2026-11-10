import {execFileSync} from 'node:child_process';

const statusText = process.platform === 'win32'
  ? execFileSync(process.env.ComSpec || 'cmd.exe',['/d','/s','/c','npx.cmd supabase status -o env'],{encoding:'utf8',stdio:['ignore','pipe','ignore']})
  : execFileSync('npx',['supabase','status','-o','env'],{encoding:'utf8',stdio:['ignore','pipe','ignore']});
const env = Object.fromEntries([...statusText.matchAll(/^([A-Z_]+)="?(.*?)"?$/gm)].map(([,k,v]) => [k, v.replace(/"$/, '')]));
if (!/^https?:\/\/127\.0\.0\.1:54321$/.test(env.API_URL || '') || !env.ANON_KEY) throw new Error('Refusing to test a non-local Supabase stack');
const api = env.API_URL.replace(/\/$/,'');
const mail = 'http://127.0.0.1:54324';
const email = `artist.rehearsal.${Date.now()}@example.test`;
const password = 'Synthetic-Auth-Only-2026!';
const headers = {apikey: env.ANON_KEY, authorization: `Bearer ${env.ANON_KEY}`, 'content-type': 'application/json'};
const signup = await fetch(`${api}/auth/v1/signup`, {method:'POST', headers, body:JSON.stringify({email,password,data:{display_name:'HTTP Rehearsal Artist'}})}).then(r=>r.json());
if (!signup.user && !signup.id) throw new Error('Signup did not create an Auth user');
if (signup.access_token) throw new Error('Unverified signup unexpectedly received a session');
const before = await fetch(`${api}/auth/v1/token?grant_type=password`, {method:'POST', headers, body:JSON.stringify({email,password})});
if (before.ok) throw new Error('Unverified user obtained a session');
let message;
for (let i=0; i<20 && !message; i++) {
  await new Promise(resolve => setTimeout(resolve, 500));
  const inbox = await fetch(`${mail}/api/v1/messages`).then(r=>r.json());
  message = inbox.messages?.find(item => item.To?.some(address => address.Address === email));
}
if (!message) throw new Error('Confirmation email was not captured');
const full = await fetch(`${mail}/api/v1/message/${message.ID}`).then(r=>r.json());
const match = `${full.HTML || ''}\n${full.Text || ''}`.match(/https?:\/\/[^"'< >\s]+\/auth\/v1\/verify[^"'< >\s]+/);
if (!match) throw new Error('Confirmation link missing');
const verifyUrl = match[0].replaceAll('&amp;', '&');
if (!verifyUrl.startsWith(`${api}/auth/v1/verify`)) throw new Error('Confirmation URL is not local');
const verified = await fetch(verifyUrl, {redirect:'manual'});
if (![200,302,303,307].includes(verified.status)) throw new Error('Confirmation failed');
const token = await fetch(`${api}/auth/v1/token?grant_type=password`, {method:'POST', headers, body:JSON.stringify({email,password})}).then(r=>r.json());
if (!token.access_token) throw new Error('Verified user did not receive a session');
const authHeaders = {...headers, authorization:`Bearer ${token.access_token}`};
const rpc = () => fetch(`${api}/rest/v1/rpc/register_current_user_as_artist`, {method:'POST',headers:authHeaders,body:JSON.stringify({p_display_name:'HTTP Rehearsal Artist'})}).then(async r => {if(!r.ok) throw new Error(`Registration failed: ${r.status}`); return r.json();});
const first = await rpc(); const second = await rpc();
if (JSON.stringify(first) !== JSON.stringify(second)) throw new Error('Registration is not idempotent');
console.log('Local Auth HTTP rehearsal PASS.');
