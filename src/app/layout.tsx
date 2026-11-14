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

const siteUrl=process.env.NEXT_PUBLIC_SITE_URL;
export const metadata:Metadata={metadataBase:new URL(siteUrl||'http://localhost:3000'),title:{default:'tRA — The Real Art',template:'%s | tRA'},description:'The Real Art is a curated assisted-commerce platform connecting art lovers with original Indian art.',alternates:{canonical:'/'},robots:siteUrl?{index:true,follow:true}:{index:false,follow:false},openGraph:{type:'website',siteName:'tRA — The Real Art',title:'tRA — The Real Art',description:'Original Indian art, curated with reverence.'}};

export default function Layout({children}:{children:React.ReactNode}){
  return <html lang="en"><body><a className="skip" href="#main">Skip to content</a><Header/><div className="demo">Public integration · Approved records only · Live bidding, payments and outbound email are disabled</div><main id="main">{children}</main><Footer/></body></html>;
}
