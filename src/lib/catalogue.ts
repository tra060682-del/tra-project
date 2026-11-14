import {cache} from 'react';
import {supabase} from '@/lib/supabase/server';

export type CatalogueArtwork={
  id:string;title:string;artistId:string;artist:string;form:string;medium:string;size:string;
  price:number;description:string;imageUrls:string[];imageAlt:string;status:'published';year:string;
};

const configured=()=>Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY);

export const catalogue=cache(async():Promise<CatalogueArtwork[]>=>{
  if(!configured())return [];
  try{
    const db=await supabase();
    const {data,error}=await db.from('artworks').select('id,title,description,year_created,width_cm,height_cm,final_price_paise,status,artist_id,artist_profiles(display_name),artwork_media(secure_url,alt_text,is_primary,is_approved,sort_order)').eq('status','published').order('published_at',{ascending:false}).limit(100);
    if(error||!data)return [];
    return data.map(row=>{
      const artist=row.artist_profiles as unknown as {display_name?:string}|null;
      const media=((row.artwork_media as unknown as {secure_url:string;alt_text?:string;is_primary:boolean;is_approved:boolean;sort_order:number}[]|null)??[])
        .filter(item=>item.is_approved&&/^https:\/\//.test(item.secure_url))
        .sort((a,b)=>Number(b.is_primary)-Number(a.is_primary)||a.sort_order-b.sort_order);
      return {id:row.id,title:row.title,artistId:row.artist_id,artist:artist?.display_name||'Approved tRA artist',form:'Original artwork',medium:'Details available on request',size:row.width_cm&&row.height_cm?`${row.width_cm} × ${row.height_cm} cm`:'Dimensions on request',price:Number(row.final_price_paise||0),description:row.description||'Details available through a tRA art advisor.',imageUrls:media.map(item=>item.secure_url),imageAlt:media[0]?.alt_text||row.title,status:'published' as const,year:row.year_created?String(row.year_created):'Year available on request'};
    });
  }catch{return []}
});

export const catalogueArtwork=cache(async(id:string)=>{
  if(!/^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(id))return null;
  return (await catalogue()).find(item=>item.id===id)??null;
});
