import Link from 'next/link';
import {logout} from '@/app/auth/actions';
import {getOptionalAuthContext} from '@/lib/auth';
import {HeartIcon,MenuIcon,SearchIcon,UserIcon} from '@/components/icons';

const navigation=[
  {label:'Artworks',href:'/artworks',items:[['All Artworks','/artworks'],['New Arrivals','/artworks?sort=newest'],['Featured Artworks','/artworks?sort=featured'],['Traditional Art','/artworks?style=Traditional+Indian'],['Contemporary Art','/artworks?style=Contemporary'],['By Style','/artworks#filters'],['By Price','/artworks?sort=price_asc'],['By Size','/artworks#filters'],['Available Now','/artworks']]},
  {label:'Artists',href:'/artists',items:[['All Artists','/artists'],['Artist Stories','/journal'],['Commission an Artist','/commissions']]},
  {label:'Collections',href:'/collections',items:[['Traditional Masters','/collections'],['Contemporary India','/collections'],['Spiritual Expressions','/collections'],['Nature and Landscapes','/collections'],["Curator's Picks",'/collections'],['New Collections','/collections']]},
  {label:'Auction Lobby',href:'/auctions',items:[['Live','/auctions#live'],['Upcoming','/auctions#upcoming'],['Completed','/auctions#completed'],['Calendar','/auctions'],['How to Bid','/auctions#how-to-bid'],['FAQs','/auctions#faq']]},
  {label:'Art Advisory',href:'/art-advisory',items:[['Find My Art','/art-advisory'],['Personalised Consultation','/art-advisory'],['Corporate Art','/corporate-art'],['Commission','/commissions'],['Interior Designers','/art-advisory'],['Sell from collection','/resale']]},
  {label:'For Artists',href:'/for-artists',items:[['Join tRA','/join-as-artist'],['Benefits','/for-artists#benefits'],['How it works','/for-artists#how-it-works'],['FAQs','/for-artists#faq'],['Intermediaries','/join-as-intermediary']]},
  {label:'About',href:'/about',items:[['Our Story','/about'],['Mission','/about#mission'],['Authenticity','/authenticity'],['Verify Certificate','/certificates/verify'],['Art Journal','/journal'],['Contact','/contact']]},
] as const;

function DesktopNavigation(){return <nav className="desktop-nav" aria-label="Main navigation">{navigation.map(item=><div className="nav-group" key={item.label}>{item.label==='Auction Lobby'?<Link href="/auctions">Auction Lobby</Link>:<Link href={item.href}>{item.label}</Link>}<div className="nav-dropdown" aria-label={`${item.label} menu`}>{item.items.map(([label,href])=><Link href={href} key={label}>{label}</Link>)}</div></div>)}</nav>}
function MobileNavigation({accountPath}:{accountPath:string}){return <details className="mobile-menu"><summary aria-label="Open navigation"><MenuIcon/></summary><nav aria-label="Mobile navigation">{navigation.map(item=><details className="mobile-nav-group" key={item.label}><summary>{item.label}<span aria-hidden="true">+</span></summary><div><Link href={item.href}>Overview</Link>{item.items.map(([label,href])=><Link href={href} key={label}>{label}</Link>)}</div></details>)}<Link href="/wishlist">Wishlist</Link><Link href={accountPath}>Account</Link><Link className="mobile-join" href="/join-as-artist">Join as Artist</Link></nav></details>}

export async function Header(){
  const context=await getOptionalAuthContext().catch(()=>null);
  const signedIn=Boolean(context),accountPath=context?.landingPath??'/login';
  return <header className="site-header">
    <Link className="brand" href="/" aria-label="The Real Art home"><strong>t<span>RA</span></strong><span>THE REAL ART</span></Link>
    <DesktopNavigation/>
    <div className="header-actions">
      <details className="header-search"><summary className="icon-link" aria-label="Search artworks"><SearchIcon/></summary><form action="/artworks" role="search"><label htmlFor="header-search">Search original art</label><div><input id="header-search" name="q" placeholder="Artist, style, subject or medium"/><button type="submit">Search</button></div></form></details>
      <Link className="icon-link" href="/wishlist" aria-label="Wishlist"><HeartIcon/></Link>
      <Link className="icon-link" href={accountPath} aria-label="Account"><UserIcon/></Link>
      {signedIn?<form action={logout}><button className="header-login" type="submit">Logout</button></form>:<Link className="header-login" href="/login">Account</Link>}
      <Link className="header-join" href="/join-as-artist">Join as Artist</Link>
      <MobileNavigation accountPath={accountPath}/>
    </div>
  </header>;
}
