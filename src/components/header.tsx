import Link from 'next/link';
import {logout} from '@/app/auth/actions';
import {supabase} from '@/lib/supabase/server';
import {BagIcon,HeartIcon,MenuIcon,SearchIcon} from '@/components/icons';

export async function Header(){
  let signedIn=false;
  if(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY){
    const db=await supabase();
    const {data:{user}}=await db.auth.getUser();
    signedIn=Boolean(user);
  }
  const navigation=<><Link href="/artworks">Artworks</Link><Link href="/for-artists">Artists</Link><Link href="/#collections">Collections</Link><Link href="/auctions">Auction Lobby</Link><Link href="/how-it-works">How It Works</Link><Link href="/for-artists">For Artists</Link><Link href="/about">About</Link><Link href="/contact">Contact</Link></>;
  return <header className="site-header"><Link className="brand" href="/" aria-label="The Reverence of Art home">tRA<span>THE REVERENCE OF ART</span></Link><nav className="desktop-nav" aria-label="Main navigation">{navigation}</nav><div className="header-actions"><Link className="icon-link" href="/artworks" aria-label="Search artworks"><SearchIcon/></Link><button className="icon-link" type="button" disabled title="Wishlist coming soon" aria-label="Wishlist coming soon"><HeartIcon/></button><button className="icon-link" type="button" disabled title="Shopping bag coming soon" aria-label="Shopping bag coming soon"><BagIcon/></button>{signedIn?<form action={logout}><button className="header-login" type="submit">Logout</button></form>:<Link className="header-login" href="/login">Login</Link>}<Link className="header-join" href="/join-as-artist">Join as Artist</Link><details className="mobile-menu"><summary aria-label="Open navigation"><MenuIcon/></summary><nav aria-label="Mobile navigation">{navigation}<Link href="/login">Login</Link><Link href="/join-as-artist">Join as Artist</Link></nav></details></div></header>
}
