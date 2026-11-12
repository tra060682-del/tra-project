import {supabase} from '@/lib/supabase/server';
export {formatInr} from '@/lib/currency';

export type AuctionLot={
  id:string;auctionTitle:string;auctionSlug:string;lotNumber:number;title:string;artist:string;
  description:string;medium:string;dimensions:string;year:string;startsAt:string;endsAt:string;
  openingPaise:number;incrementPaise:number;currentPaise:number|null;reserveMet:boolean|null;
  bidCount:number;status:'live'|'upcoming'|'completed';tone:string;imageUrl:string|null;biddingEnabled:boolean;
};

const demoLots:AuctionLot[]=[
  {id:'monsoon-courtyard',auctionTitle:'The India Edit',auctionSlug:'the-india-edit',lotNumber:1,title:'Monsoon Courtyard',artist:'Illustrative artist',description:'An editorial study of architecture, rain and remembered light. Displayed for auction-interface review only.',medium:'Mixed media study',dimensions:'90 × 120 cm',year:'2026',startsAt:'2026-11-01T10:00:00.000Z',endsAt:'2027-01-15T12:30:00.000Z',openingPaise:18000000,incrementPaise:1000000,currentPaise:24000000,reserveMet:true,bidCount:7,status:'live',tone:'water',imageUrl:null,biddingEnabled:false},
  {id:'keepers-of-the-grove',auctionTitle:'Living Traditions',auctionSlug:'living-traditions',lotNumber:4,title:'Keepers of the Grove',artist:'Illustrative artist',description:'A decorative forest study inspired by Indian narrative painting traditions. Not verified inventory.',medium:'Pigment study on paper',dimensions:'75 × 100 cm',year:'2026',startsAt:'2027-02-10T10:00:00.000Z',endsAt:'2027-02-12T13:00:00.000Z',openingPaise:14000000,incrementPaise:500000,currentPaise:null,reserveMet:null,bidCount:0,status:'upcoming',tone:'forest',imageUrl:null,biddingEnabled:false},
  {id:'lotus-procession',auctionTitle:'Sacred Geometry',auctionSlug:'sacred-geometry',lotNumber:8,title:'Lotus Procession',artist:'Illustrative artist',description:'A richly layered devotional composition created as an interface placeholder, not an auction consignment.',medium:'Natural pigment study',dimensions:'100 × 100 cm',year:'2026',startsAt:'2026-08-05T10:00:00.000Z',endsAt:'2026-08-07T13:00:00.000Z',openingPaise:22000000,incrementPaise:1000000,currentPaise:31000000,reserveMet:true,bidCount:12,status:'completed',tone:'lotus',imageUrl:null,biddingEnabled:false},
  {id:'earth-script',auctionTitle:'Contemporary India',auctionSlug:'contemporary-india',lotNumber:2,title:'Earth Script',artist:'Illustrative artist',description:'A modern material study for layout review. It does not represent approved inventory.',medium:'Mixed media study',dimensions:'80 × 110 cm',year:'2026',startsAt:'2027-03-20T10:00:00.000Z',endsAt:'2027-03-22T13:00:00.000Z',openingPaise:16000000,incrementPaise:750000,currentPaise:null,reserveMet:null,bidCount:0,status:'upcoming',tone:'earth',imageUrl:null,biddingEnabled:false},
];

const n=(value:unknown)=>typeof value==='number'?value:Number(value||0);
export async function getAuctionLots():Promise<AuctionLot[]>{
  if(!process.env.NEXT_PUBLIC_SUPABASE_URL||!process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)return demoLots;
  try{
    const db=await supabase();
    const {data,error}=await db.from('public_auction_lots').select('*').order('starts_at',{ascending:true});
    if(error||!data?.length)return demoLots;
    const now=Date.now();
    return data.map((row:Record<string,unknown>)=>({
      id:String(row.id),auctionTitle:String(row.auction_title),auctionSlug:String(row.auction_slug),lotNumber:n(row.lot_number),
      title:String(row.artwork_title),artist:String(row.artist_name||'Artist'),description:String(row.artwork_description||''),
      medium:'Original artwork',dimensions:[row.width_cm,row.height_cm].filter(Boolean).join(' × ')+' cm',year:String(row.year_created||'—'),
      startsAt:String(row.starts_at),endsAt:String(row.ends_at),openingPaise:n(row.opening_paise),incrementPaise:n(row.increment_paise),
      currentPaise:row.current_paise===null?null:n(row.current_paise),reserveMet:row.disclose_reserve_status?Boolean(row.reserve_met):null,
      bidCount:n(row.bid_count),status:Date.parse(String(row.starts_at))>now?'upcoming':Date.parse(String(row.ends_at))<=now?'completed':'live',
      tone:['forest','water','lotus','earth'][n(row.lot_number)%4],imageUrl:row.image_url?String(row.image_url):null,biddingEnabled:Boolean(row.bidding_enabled),
    }));
  }catch{return demoLots;}
}

export async function getAuctionLot(id:string){return (await getAuctionLots()).find(lot=>lot.id===id)??null;}
