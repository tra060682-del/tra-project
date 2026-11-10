import type {Metadata} from 'next';
import {Header} from '@/components/header';
import Link from 'next/link';
import './globals.css';
import './auth.css';

export const metadata:Metadata={title:{default:'tRA — Original Indian art, thoughtfully curated',template:'%s | tRA'},description:'Discover original Indian paintings and a personal approach to collecting.'};

export default function Layout({children}:{children:React.ReactNode}){return <html lang="en"><body><a className="skip" href="#main">Skip to content</a><Header/><div className="demo">DESIGN PREVIEW · Sample catalogue and illustrative art · Live sales are not enabled</div><main id="main">{children}</main><footer><div className="brand">tRA<span>THE REAL ART</span></div><p>Art with a story.<br/>A place in yours.</p><div><Link href="/about">Our story</Link><Link href="/contact">Contact</Link><Link href="/privacy">Privacy</Link><Link href="/terms">Terms</Link></div><small>India · INR<br/>Certificates are issued and signed by the artist.</small></footer></body></html>}
