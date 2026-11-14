import {cache} from 'react';
import {supabase} from '@/lib/supabase/server';
export {formatInr} from '@/lib/currency';

export type AuctionLot={id:string;auctionTitle:string;auctionSlug:string;lotNumber:number;title:string;artist:string;description:string;medium:string;dimensions:string;year:string;startsAt:string;endsAt:string;openingPaise:number;incrementPaise:number;currentPaise:number|null;reserveMet:boolean|null;bidCount:number;status:'live'|'upcoming'|'completed';tone:string;imageUrl:string|null;biddingEnabled:boolean};
const n=(value:unknown)=>typeof value==='number'?value:Number(value||0);

export const getAuctionLots=cache(async():Promise<AuctionLot[]>=>{
  if(!process.env.NEXT_PUBLIC_SUPABASE_URL||!process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)return [];
  try{
    const db=await supabase();
    const {data,error}=await db.from('public_auction_lots').select('*').order('starts_at',{ascending:true});
    if(error||!data)return [];
    const now=Date.now();
    return data.map((row:Record<string,unknown>)=>({id:String(row.id),auctionTitle:String(row.auction_title),auctionSlug:String(row.auction_slug),lotNumber:n(row.lot_number),title:String(row.artwork_title),artist:String(row.artist_name||'Artist'),description:String(row.artwork_description||''),medium:'Original artwork',dimensions:[row.width_cm,row.height_cm].filter(Boolean).join(' × ')+' cm',year:String(row.year_created||'—'),startsAt:String(row.starts_at),endsAt:String(row.ends_at),openingPaise:n(row.opening_paise),incrementPaise:n(row.increment_paise),currentPaise:row.current_paise===null?null:n(row.current_paise),reserveMet:row.disclose_reserve_status?Boolean(row.reserve_met):null,bidCount:n(row.bid_count),status:Date.parse(String(row.starts_at))>now?'upcoming':Date.parse(String(row.ends_at))<=now?'completed':'live',tone:['forest','water','lotus','earth'][n(row.lot_number)%4],imageUrl:row.image_url?String(row.image_url):null,biddingEnabled:false}));
  }catch{return []}
});
export const getAuctionLot=cache(async(id:string)=>(await getAuctionLots()).find(lot=>lot.id===id)??null);
