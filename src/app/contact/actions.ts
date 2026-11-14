'use server';
import {redirect} from 'next/navigation';
import {z} from 'zod';
import {supabase} from '@/lib/supabase/server';

const TYPES=['artwork','artist','advisory','commission','corporate','resale','contact'] as const;
const RETURN_PATHS=new Set(['/contact','/art-advisory','/commissions','/corporate-art','/resale']);
export async function submitEnquiry(form:FormData){
  const value=(name:string)=>String(form.get(name)??'').trim();
  const parsed=z.object({type:z.enum(TYPES),returnPath:z.string(),artworkId:z.union([z.uuid(),z.literal('')]),name:z.string().min(2).max(160),email:z.email(),phone:z.string().max(50),message:z.string().min(10).max(4000),consent:z.literal(true)}).safeParse({type:value('type'),returnPath:value('returnPath'),artworkId:value('artworkId'),name:value('name'),email:value('email').toLowerCase(),phone:value('phone'),message:value('message'),consent:form.get('consent')==='on'});
  const path=parsed.success&&RETURN_PATHS.has(parsed.data.returnPath)?parsed.data.returnPath:'/contact';
  if(!parsed.success)redirect(`${path}?error=${encodeURIComponent('Please complete the required fields and consent.')}`);
  let failure='';
  try{
    const db=await supabase();
    const message=`[${parsed.data.type.toUpperCase()} ENQUIRY]\n${parsed.data.message}`;
    const {error}=await db.rpc('tra_submit_enquiry',{p_artwork_id:parsed.data.artworkId||null,p_name:parsed.data.name,p_email:parsed.data.email,p_phone:parsed.data.phone||null,p_message:message,p_city:null,p_state:null,p_consent:true});
    if(error)failure='Your enquiry could not be recorded. Please try again.';
  }catch{failure='Secure enquiry storage is not configured in this environment.'}
  if(failure)redirect(`${path}?error=${encodeURIComponent(failure)}`);
  redirect(`${path}?message=${encodeURIComponent('Thank you. Your enquiry has been recorded for the tRA team. No email has been sent.')}`);
}
