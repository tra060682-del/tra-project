import Link from 'next/link';

const columns=[
  {title:'Collect',links:[['Artworks','/artworks'],['Artists','/artists'],['Collections','/collections'],['Auction Lobby','/auctions'],['Art Journal','/journal']]},
  {title:'Services',links:[['Find My Art','/art-advisory'],['Personalised Consultation','/art-advisory'],['Corporate Art','/corporate-art'],['Commission an Artist','/commissions'],['Sell from collection','/resale']]},
  {title:'Artists',links:[['Join tRA','/join-as-artist'],['Artist benefits','/for-artists#benefits'],['How it works','/for-artists#how-it-works'],['Artist FAQs','/for-artists#faq'],['Intermediaries','/join-as-intermediary']]},
  {title:'tRA',links:[['Our Story','/about'],['Authenticity','/authenticity'],['Verify Certificate','/certificates/verify'],['Contact','/contact'],['Legal & Policies','/legal']]},
] as const;

export function Footer(){return <footer className="site-footer tra-footer"><div className="footer-architecture" aria-hidden="true"/><div className="footer-brand"><Link className="brand footer-logo" href="/" aria-label="The Real Art home"><strong>t<span>RA</span></strong></Link><h2>tRA — The Real Art</h2><p>Discover. Collect. Commission. Bid.</p><p>A curated home for original Indian art — connecting artists, collectors and galleries through trusted sales, auctions, advisory and commissions.</p><a href="mailto:hello@therealart.in">hello@therealart.in</a><small>© 2026 tRA. All rights reserved.</small></div>{columns.map(column=><div className="footer-column" key={column.title}><h3>{column.title}</h3>{column.links.map(([label,href])=><Link href={href} key={label}>{label}</Link>)}</div>)}<div className="footer-status"><span>Test environment</span><p>Payments, live bidding and outbound email remain disabled.</p><div><Link href="/privacy">Privacy</Link><Link href="/terms">Terms</Link></div></div></footer>}
