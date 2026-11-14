import type {Metadata} from 'next';
import {notFound} from 'next/navigation';
import Link from 'next/link';
import {PublishedArtworkImage} from '@/components/public-content';
import {catalogueArtwork} from '@/lib/catalogue';
import {inr} from '@/lib/format';

type Props={params:Promise<{slug:string}>};
export async function generateMetadata({params}:Props):Promise<Metadata>{const {slug}=await params;const art=await catalogueArtwork(slug);if(!art)return {title:'Artwork unavailable',robots:{index:false,follow:false}};return {title:art.title,description:art.description,alternates:{canonical:`/artworks/${art.id}`}}}
export default async function Detail({params}:Props){const {slug}=await params;const art=await catalogueArtwork(slug);if(!art)notFound();const structured={"@context":"https://schema.org","@type":"VisualArtwork",name:art.title,creator:{"@type":"Person",name:art.artist},artMedium:art.medium,image:art.imageUrls};return <section className="section public-artwork-detail"><script type="application/ld+json" dangerouslySetInnerHTML={{__html:JSON.stringify(structured).replace(/</g,'\\u003c')}}/><div className="public-gallery">{art.imageUrls.length?art.imageUrls.map((src,index)=><PublishedArtworkImage key={src} src={src} alt={index?`${art.title}, detail ${index+1}`:art.imageAlt}/>):<PublishedArtworkImage alt={art.title}/>}</div><article><Link href="/artworks">← The collection</Link><div className="eyebrow">{art.form} · PUBLISHED INVENTORY</div><h1>{art.title}</h1><p className="public-byline">By <Link href={`/artists/${art.artistId}`}>{art.artist}</Link></p>{art.price>0&&<h2>{inr(art.price)}</h2>}<dl><dt>Medium</dt><dd>{art.medium}</dd><dt>Dimensions</dt><dd>{art.size}</dd><dt>Year</dt><dd>{art.year}</dd><dt>Availability</dt><dd>Available for assisted enquiry, subject to confirmation</dd></dl><p>{art.description}</p><Link className="button" href={`/contact?artwork=${art.id}&reason=artwork`}>Enquire about this artwork ↗</Link></article></section>}
