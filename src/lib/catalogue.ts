import {cache} from 'react';
import {supabase} from '@/lib/supabase/server';

export type CatalogueArtwork={
  id:string;title:string;artistId:string;artist:string;form:string;medium:string;size:string;
  price:number;description:string;imageUrls:string[];imageAlt:string;status:'published';year:string;
  category:string;subjects:string[];artforms:string[];styles:string[];featured:boolean;createdAt:string;
  isFixture?:boolean;sourceUrl?:string;rightsLabel?:string;
};

const configured=()=>Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY);

export const catalogue=cache(async():Promise<CatalogueArtwork[]>=>{
  if(!configured())return [];
  try{
    const db=await supabase();
    const {data,error}=await db.from('artworks').select('id,title,description,year_created,width_cm,height_cm,final_price_paise,status,artist_id,category_id,medium_id,style_id,subject_id,published_at,created_at,artist_profiles(display_name),artwork_media(secure_url,alt_text,is_primary,is_approved,sort_order)').eq('status','published').order('published_at',{ascending:false}).limit(100);
    if(error||!data)return [];
    const taxonomyIds=[...new Set(data.flatMap(row=>[row.category_id,row.medium_id,row.style_id,row.subject_id]).filter((id):id is string=>Boolean(id)))];
    const terms=new Map<string,{code:string;label:string}>();
    if(taxonomyIds.length){
      const {data:taxonomy}=await db.from('taxonomies').select('id,code,label,taxonomy_type').in('id',taxonomyIds).eq('is_active',true);
      taxonomy?.forEach(term=>terms.set(term.id,{code:term.code,label:term.label}));
    }
    return data.map(row=>{
      const artist=row.artist_profiles as unknown as {display_name?:string}|null;
      const media=((row.artwork_media as unknown as {secure_url:string;alt_text?:string;is_primary:boolean;is_approved:boolean;sort_order:number}[]|null)??[])
        .filter(item=>item.is_approved&&/^https:\/\//.test(item.secure_url))
        .sort((a,b)=>Number(b.is_primary)-Number(a.is_primary)||a.sort_order-b.sort_order);
      const category=terms.get(row.category_id??'');
      const medium=terms.get(row.medium_id??'');
      const style=terms.get(row.style_id??'');
      const subject=terms.get(row.subject_id??'');
      return {id:row.id,title:row.title,artistId:row.artist_id,artist:artist?.display_name||'Approved tRA artist',form:category?.label||'Original artwork',medium:medium?.label||'Details available on request',size:row.width_cm&&row.height_cm?`${row.width_cm} × ${row.height_cm} cm`:'Dimensions on request',price:Number(row.final_price_paise||0),description:row.description||'Details available through a tRA art advisor.',imageUrls:media.map(item=>item.secure_url),imageAlt:media[0]?.alt_text||row.title,status:'published' as const,year:row.year_created?String(row.year_created):'Year available on request',category:category?.code||'',subjects:subject?[subject.label]:[],artforms:[],styles:style?[style.label]:[],featured:false,createdAt:row.published_at||row.created_at||''};
    });
  }catch{return []}
});

export const catalogueArtwork=cache(async(id:string,allowFixture=false)=>{
  if(!/^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(id))return null;
  const published=(await catalogue()).find(item=>item.id===id);
  if(published)return published;
  if(allowFixture&&process.env.NODE_ENV!=='production'){
    const {approvedMediaFixtures}=await import('@/lib/catalogue-parity');
    return approvedMediaFixtures().find(item=>item.id===id)??null;
  }
  return null;
});
