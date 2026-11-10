import {createClient} from '@supabase/supabase-js';

const {DEV_SUPABASE_URL, DEV_SUPABASE_SERVICE_ROLE_KEY, DEV_SUPABASE_PROJECT_REF, PROD_SUPABASE_PROJECT_REF} = process.env;
if (!DEV_SUPABASE_URL || !DEV_SUPABASE_SERVICE_ROLE_KEY || !DEV_SUPABASE_PROJECT_REF) throw new Error('Development cleanup environment is incomplete');
const url = new URL(DEV_SUPABASE_URL);
if (url.hostname !== `${DEV_SUPABASE_PROJECT_REF}.supabase.co`) throw new Error('Development URL/project mismatch');
if (DEV_SUPABASE_PROJECT_REF === PROD_SUPABASE_PROJECT_REF) throw new Error('Refusing cleanup against production');
const admin = createClient(DEV_SUPABASE_URL, DEV_SUPABASE_SERVICE_ROLE_KEY, {auth:{persistSession:false}});

const users = [];
for (let page=1;;page++) {
  const result = await admin.auth.admin.listUsers({page,perPage:100});
  if (result.error) throw result.error;
  users.push(...result.data.users.filter(user => /^ci\..+@example\.test$/.test(user.email || '')));
  if (result.data.users.length < 100) break;
}
for (const user of users) {
  const prepared = await admin.rpc('tra_cleanup_development_synthetic_user',{p_user_id:user.id});
  if (prepared.error) throw prepared.error;
  const removed = await admin.auth.admin.deleteUser(user.id);
  if (removed.error) throw removed.error;
}
console.log(`Removed ${users.length} synthetic development Auth user(s).`);
