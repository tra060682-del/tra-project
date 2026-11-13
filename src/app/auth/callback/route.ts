import {NextResponse} from 'next/server';
import {supabase} from '@/lib/supabase/server';
import {dashboardPathForRoles,isTraRole} from '@/lib/rbac';

function safeNext(candidate:string|null,fallback:string){return candidate?.startsWith('/')&&!candidate.startsWith('//')?candidate:fallback}

export async function GET(request:Request){
  const url=new URL(request.url);
  const code=url.searchParams.get('code');
  if(!code)return NextResponse.redirect(new URL('/login?error=The+verification+link+is+invalid+or+expired.',url.origin));
  const db=await supabase();
  const {error}=await db.auth.exchangeCodeForSession(code);
  if(error)return NextResponse.redirect(new URL('/login?error=The+verification+link+is+invalid+or+expired.',url.origin));
  if(url.searchParams.get('intent')==='artist'){
    const {error:roleError}=await db.rpc('register_current_user_as_artist',{});
    if(roleError){await db.auth.signOut();return NextResponse.redirect(new URL('/login?error=Your+artist+workspace+could+not+be+prepared.+Please+contact+support.',url.origin))}
  }
  if(url.searchParams.get('intent')==='intermediary'){
    const {data:{user}}=await db.auth.getUser();
    const {error:roleError}=await db.rpc('register_current_user_as_intermediary',{p_display_name:user?.user_metadata?.display_name||'',p_organisation:user?.user_metadata?.organisation_name||null});
    if(roleError){await db.auth.signOut();return NextResponse.redirect(new URL('/login?error=Your+intermediary+workspace+could+not+be+prepared.+Please+contact+support.',url.origin))}
  }
  const {data:{user}}=await db.auth.getUser();
  if(!user)return NextResponse.redirect(new URL('/login?error=Authentication+could+not+be+completed.',url.origin));
  const {data:roles}=await db.from('user_roles').select('role').eq('user_id',user.id);
  const fallback=dashboardPathForRoles((roles??[]).map(row=>row.role).filter(isTraRole));
  return NextResponse.redirect(new URL(safeNext(url.searchParams.get('next'),fallback),url.origin));
}
