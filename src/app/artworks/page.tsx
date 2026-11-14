import type {Metadata} from 'next';
import Link from 'next/link';
import {ArtworkCards,AvailabilityState} from '@/components/public-content';
import {catalogue} from '@/lib/catalogue';

export const metadata:Metadata={title:'Original Artworks',description:'Browse original Indian artworks approved for public display by tRA.',alternates:{canonical:'/artworks'}};
type Query={q?:string;artist?:string;budget?:string;sort?:string};

export default async function Browse({searchParams}:{searchParams:Promise<Query>}){
  const query=await searchParams;
  const records=await catalogue();
  const term=(query.q||'').trim().toLowerCase();
  const filtered=records.filter(item=>(!term||`${item.title} ${item.artist} ${item.description}`.toLowerCase().includes(term))&&(!query.artist||item.artistId===query.artist)&&(!query.budget||item.price===0||item.price<=Number(query.budget)));
  const sorted=[...filtered].sort((a,b)=>query.sort==='price_asc'?a.price-b.price:query.sort==='price_desc'?b.price-a.price:a.title.localeCompare(b.title));
  const artists=[...new Map(records.map(item=>[item.artistId,item.artist])).entries()];
  return <section className="section public-index"><div className="eyebrow">THE COLLECTION</div><h1>Art worth living with.</h1><p className="intro">Only approved, published inventory appears here. Private drafts and staged migration records are never included.</p><form className="public-filters" role="search"><label>Search<input name="q" defaultValue={query.q} placeholder="Artwork, artist or subject"/></label><label>Artist<select name="artist" defaultValue={query.artist||''}><option value="">All published artists</option>{artists.map(([id,name])=><option key={id} value={id}>{name}</option>)}</select></label><label>Budget<select name="budget" defaultValue={query.budget||''}><option value="">Any listed price</option><option value="4000000">Up to ₹40,000</option><option value="10000000">Up to ₹1,00,000</option></select></label><label>Sort<select name="sort" defaultValue={query.sort||''}><option value="">Title</option><option value="price_asc">Price: low to high</option><option value="price_desc">Price: high to low</option></select></label><button className="button">Apply filters</button><Link href="/artworks">Reset</Link></form><p className="public-result-count" aria-live="polite">{sorted.length} approved artwork{sorted.length===1?'':'s'}</p>{sorted.length?<ArtworkCards artworks={sorted}/>:<AvailabilityState title={records.length?'No artworks match these filters.':'The public collection is being prepared.'}><p>{records.length?'Try a broader search or reset the filters.':'No approved published artworks are available through the current public contract. Staged records have not been promoted.'}</p></AvailabilityState>}</section>;
}
