import {cache} from 'react';
import {supabase} from '@/lib/supabase/server';
import {catalogue,type CatalogueArtwork} from '@/lib/catalogue';

const configured=()=>Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY);

export type PublicArtist={id:string;name:string;biography:string;statement:string;location:string;website:string;portrait:string|null;artworks:CatalogueArtwork[]};
export type PublicCollection={id:string;slug:string;title:string;description:string;artworks:CatalogueArtwork[]};
export type JournalEntry={id:string;slug:string;title:string;body:string;updatedAt:string};

export const publicArtists=cache(async():Promise<PublicArtist[]>=>{
  if(!configured())return [];
  try{
    const db=await supabase();
    const {data,error}=await db.from('artist_profiles').select('id,display_name,biography,artist_statement,city,state,country,website,profile_image_url').eq('status','approved').eq('public_visible',true).order('display_name');
    if(error||!data)return [];
    const works=await catalogue();
    return data.map(row=>({id:row.id,name:row.display_name||'tRA artist',biography:row.biography||'',statement:row.artist_statement||'',location:[row.city,row.state,row.country].filter(Boolean).join(', '),website:row.website||'',portrait:row.profile_image_url&&/^https:\/\//.test(row.profile_image_url)?row.profile_image_url:null,artworks:works.filter(work=>work.artistId===row.id)}));
  }catch{return []}
});

export const publicArtist=cache(async(id:string)=>(await publicArtists()).find(item=>item.id===id)??null);

export const publicCollections=cache(async():Promise<PublicCollection[]>=>{
  if(!configured())return [];
  try{
    const db=await supabase();
    const {data,error}=await db.from('collections').select('id,slug,title,description,collection_artworks(artwork_id,sort_order)').eq('is_published',true).order('sort_order');
    if(error||!data)return [];
    const works=await catalogue();
    return data.map(row=>{
      const joins=((row.collection_artworks as unknown as {artwork_id:string;sort_order:number}[]|null)??[]).sort((a,b)=>a.sort_order-b.sort_order);
      return {id:row.id,slug:row.slug,title:row.title,description:row.description||'',artworks:joins.map(join=>works.find(work=>work.id===join.artwork_id)).filter((work):work is CatalogueArtwork=>Boolean(work))};
    });
  }catch{return []}
});

export const publicCollection=cache(async(slug:string)=>(await publicCollections()).find(item=>item.slug===slug)??null);

export const journalEntries=cache(async():Promise<JournalEntry[]>=>{
  if(!configured())return [];
  try{
    const db=await supabase();
    const {data,error}=await db.from('content_pages').select('id,slug,title,body,updated_at').eq('is_published',true).like('slug','journal-%').order('updated_at',{ascending:false});
    if(error||!data)return [];
    return data.map(row=>({id:row.id,slug:String(row.slug).replace(/^journal-/,''),title:row.title,body:row.body,updatedAt:row.updated_at}));
  }catch{return []}
});

export const journalEntry=cache(async(slug:string)=>(await journalEntries()).find(item=>item.slug===slug)??null);

export const publicDataConfigured=configured;
