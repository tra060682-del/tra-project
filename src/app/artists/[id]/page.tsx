import type {Metadata} from 'next';
import {notFound} from 'next/navigation';
import Link from 'next/link';
import {ArtworkCards,PublishedArtworkImage} from '@/components/public-content';
import {publicArtist} from '@/lib/public-content';
type Props={params:Promise<{id:string}>};
export async function generateMetadata({params}:Props):Promise<Metadata>{const artist=await publicArtist((await params).id);return artist?{title:artist.name,description:artist.biography||`Approved tRA artist profile for ${artist.name}.`,alternates:{canonical:`/artists/${artist.id}`}}:{title:'Artist unavailable',robots:{index:false,follow:false}}}
export default async function Artist({params}:Props){const artist=await publicArtist((await params).id);if(!artist)notFound();return <section className="section artist-profile"><div className="artist-profile-hero"><PublishedArtworkImage src={artist.portrait||artist.artworks[0]?.imageUrls[0]} alt={artist.portrait?`Portrait of ${artist.name}`:`Selected work by ${artist.name}`}/><div><Link href="/artists">← Artist directory</Link><p className="eyebrow">APPROVED tRA ARTIST</p><h1>{artist.name}</h1>{artist.location&&<p>{artist.location}</p>}<p className="intro">{artist.biography||'Biography available on request.'}</p>{artist.statement&&<blockquote>{artist.statement}</blockquote>}</div></div><div className="public-section-heading"><p className="eyebrow">PUBLISHED WORKS</p><h2>Works by {artist.name}</h2></div>{artist.artworks.length?<ArtworkCards artworks={artist.artworks}/>:<p>No published works are currently attached to this public profile.</p>}</section>}
