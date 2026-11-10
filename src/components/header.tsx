import Link from 'next/link';
import {logout} from '@/app/auth/actions';
import {supabase} from '@/lib/supabase/server';

export async function Header(){
  let signedIn=false;
  if(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY){
    const db=await supabase();
    const {data:{user}}=await db.auth.getUser();
    signedIn=Boolean(user);
  }
  return <><div className="announcement">Original Indian art. Personal guidance. A considered way to collect.</div><header><Link className="brand" href="/" aria-label="The Real Art home">tRA<span>THE REAL ART</span></Link><nav aria-label="Main navigation"><Link href="/artworks">Discover art</Link><Link href="/how-it-works">How it works</Link><Link href="/for-artists">For artists</Link><Link href="/join-as-artist">Join as Artist</Link></nav>{signedIn?<form action={logout}><button className="text-link link-button" type="submit">Sign out ↗</button></form>:<Link className="text-link" href="/login">Sign in ↗</Link>}</header></>
}
