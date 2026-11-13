import type {Metadata} from 'next';
import '@fontsource-variable/lora';
import '@fontsource-variable/lora/wght-italic.css';
import '@fontsource-variable/dm-sans';
import '@fontsource/ibm-plex-mono/400.css';
import '@fontsource/ibm-plex-mono/500.css';
import {Header} from '@/components/header';
import {Footer} from '@/components/footer';
import './globals.css';
import './auth.css';
import './design-system.css';

export const metadata:Metadata={title:{default:'tRA — The Real Art',template:'%s | tRA'},description:'The Real Art is a curated assisted-commerce platform connecting art lovers with original Indian art.'};

export default function Layout({children}:{children:React.ReactNode}){
  return <html lang="en"><body><a className="skip" href="#main">Skip to content</a><Header/><div className="demo">Catalogue preview · Unverified sample records are clearly labelled · Live sales are not enabled</div><main id="main">{children}</main><Footer/></body></html>;
}
