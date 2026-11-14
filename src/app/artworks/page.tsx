import type {Metadata} from 'next';
import {CatalogueBrowser} from '@/components/catalogue-browser';
import {catalogue} from '@/lib/catalogue';
import {approvedMediaFixtures} from '@/lib/catalogue-parity';

type Query=Record<string,string|string[]|undefined>;
export async function generateMetadata({searchParams}:{searchParams:Promise<Query>}):Promise<Metadata>{
  const query=await searchParams;const preview=query.preview==='approved-media';
  return {title:'Browse original art',description:"Hand-painted works from India's living traditions, each reviewed by our curators.",alternates:{canonical:'/artworks'},robots:preview?{index:false,follow:false}:undefined};
}

export default async function Browse({searchParams}:{searchParams:Promise<Query>}){
  const query=await searchParams;
  const fixtureMode=process.env.NODE_ENV!=='production'&&query.preview==='approved-media';
  const records=fixtureMode?approvedMediaFixtures():await catalogue();
  const serialised=new URLSearchParams();
  for(const [key,value] of Object.entries(query)){if(Array.isArray(value))value.forEach(item=>serialised.append(key,item));else if(value)serialised.set(key,value)}
  return <CatalogueBrowser records={records} initialQuery={serialised.toString()} fixtureMode={fixtureMode}/>;
}
