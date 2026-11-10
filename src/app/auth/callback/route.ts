import {NextResponse} from 'next/server';
import {supabase} from '@/lib/supabase/server';

function safeNext(candidate:string|null){return candidate?.startsWith('/')&&!candidate.startsWith('//')?candidate:'/artist'}

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
  return NextResponse.redirect(new URL(safeNext(url.searchParams.get('next')),url.origin));
}
