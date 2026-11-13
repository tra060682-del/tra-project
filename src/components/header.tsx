import Link from 'next/link';
import {logout} from '@/app/auth/actions';
import {supabase} from '@/lib/supabase/server';
import {HeartIcon,MenuIcon,SearchIcon,UserIcon} from '@/components/icons';

export async function Header(){
  let signedIn=false;
  if(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY){const db=await supabase();const {data:{user}}=await db.auth.getUser();signedIn=Boolean(user)}
  const navLinks=<><Link href="/artworks">Artworks</Link><Link href="/artists">Artists</Link><Link href="/collections">Collections</Link><Link href="/auctions">Auction Lobby</Link><Link href="/contact?reason=art-advisory">Art Advisory</Link><Link href="/for-artists">For Artists</Link><Link href="/about">About</Link><Link href="/contact">Contact</Link></>;
  return <header className="site-header"><Link className="brand" href="/" aria-label="The Real Art home"><strong>t<span>RA</span></strong><span>THE REAL ART</span></Link><nav className="desktop-nav" aria-label="Main navigation">{navLinks}</nav><div className="header-actions"><form action="/artworks" role="search"><label className="sr-only" htmlFor="header-search">Search artworks</label><input className="sr-only" id="header-search" name="q"/><button className="icon-link" aria-label="Search artworks"><SearchIcon/></button></form><Link className="icon-link" href="/wishlist" aria-label="Wishlist"><HeartIcon/></Link><Link className="icon-link" href={signedIn?'/artist':'/login'} aria-label="Account"><UserIcon/></Link>{signedIn?<form action={logout}><button className="header-login" type="submit">Logout</button></form>:<Link className="header-login" href="/login">Account</Link>}<Link className="header-join" href="/join-as-artist">Join as Artist</Link><details className="mobile-menu"><summary aria-label="Open navigation"><MenuIcon/></summary><nav aria-label="Mobile navigation">{navLinks}<Link href="/wishlist">Wishlist</Link><Link href={signedIn?'/artist':'/login'}>Account</Link><Link href="/join-as-artist">Join as Artist</Link></nav></details></div></header>;
}
