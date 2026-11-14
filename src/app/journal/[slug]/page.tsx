import type {Metadata} from 'next';
import {notFound} from 'next/navigation';
import Link from 'next/link';
import {journalEntry} from '@/lib/public-content';
type Props={params:Promise<{slug:string}>};
export async function generateMetadata({params}:Props):Promise<Metadata>{const entry=await journalEntry((await params).slug);return entry?{title:entry.title,description:entry.body.slice(0,155),alternates:{canonical:`/journal/${entry.slug}`}}:{title:'Journal entry unavailable',robots:{index:false,follow:false}}}
export default async function Article({params}:Props){const entry=await journalEntry((await params).slug);if(!entry)notFound();return <article className="section journal-article"><Link href="/journal">← Art Journal</Link><p className="eyebrow">tRA EDITORIAL</p><h1>{entry.title}</h1><p className="journal-date">Updated {new Date(entry.updatedAt).toLocaleDateString('en-NZ',{dateStyle:'long'})}</p><div className="journal-body">{entry.body.split(/\n{2,}/).map((paragraph,index)=><p key={index}>{paragraph}</p>)}</div></article>}
