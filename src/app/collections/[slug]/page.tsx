import type {Metadata} from 'next';
import {notFound} from 'next/navigation';
import Link from 'next/link';
import {ArtworkCards,AvailabilityState} from '@/components/public-content';
import {publicCollection} from '@/lib/public-content';
type Props={params:Promise<{slug:string}>};
export async function generateMetadata({params}:Props):Promise<Metadata>{const collection=await publicCollection((await params).slug);return collection?{title:collection.title,description:collection.description,alternates:{canonical:`/collections/${collection.slug}`}}:{title:'Collection unavailable',robots:{index:false,follow:false}}}
export default async function Collection({params}:Props){const collection=await publicCollection((await params).slug);if(!collection)notFound();return <section className="section public-index"><Link href="/collections">← Curated collections</Link><p className="eyebrow">CURATED COLLECTION</p><h1>{collection.title}</h1><p className="intro">{collection.description}</p>{collection.artworks.length?<ArtworkCards artworks={collection.artworks}/>:<AvailabilityState title="This collection has no public works yet."><p>Only approved, published artworks can appear in this collection.</p></AvailabilityState>}</section>}
