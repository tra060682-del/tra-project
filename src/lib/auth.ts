import {redirect} from 'next/navigation';import {supabase} from './supabase/server';
export type StaffRole='super_admin'|'admin'|'intermediary'|'artist'|'curator';
export async function requireRole(allowed:StaffRole[]){if(!process.env.NEXT_PUBLIC_SUPABASE_URL)redirect('/login?reason=setup');const db=await supabase();const {data:{user}}=await db.auth.getUser();if(!user)redirect('/login');const {data,error}=await db.from('user_roles').select('role').eq('user_id',user.id);if(error||!data?.some(r=>allowed.includes(r.role as StaffRole)))redirect('/access-denied');return {db,user};}
