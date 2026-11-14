import type {Metadata} from 'next';
import Link from 'next/link';
import {ArtworkImage} from '@/components/artwork-image';
import {AvailabilityState} from '@/components/public-content';
import {mediaById} from '@/data/approved-media';
import {journalEntries} from '@/lib/public-content';
export const metadata:Metadata={title:'Art Journal',description:'Editorial stories and guides published by The Real Art.',alternates:{canonical:'/journal'}};
export default async function Journal(){const entries=await journalEntries();return <section className="section journal-index"><div className="journal-hero"><div><p className="eyebrow">THE ART JOURNAL</p><h1>Stories, practices and ways of seeing.</h1><p className="intro">Only editorial entries marked published in the approved content contract appear here.</p></div><ArtworkImage media={mediaById('bharat-mata')} ratio="4 / 3" zoom/></div>{entries.length?<div className="journal-grid">{entries.map(entry=><Link href={`/journal/${entry.slug}`} className="journal-card" key={entry.id}><small>tRA EDITORIAL · {new Date(entry.updatedAt).toLocaleDateString('en-NZ',{dateStyle:'medium'})}</small><h2>{entry.title}</h2><p>{entry.body.slice(0,180)}{entry.body.length>180?'…':''}</p><span>Read article →</span></Link>)}</div>:<AvailabilityState title="The journal is being edited."><p>No editorial entry is currently published under the approved journal contract. Staged articles remain private.</p></AvailabilityState>}</section>}
