import type {Metadata} from 'next';
import {EnquiryPage,type EnquiryType} from '@/components/enquiry-page';
export const metadata:Metadata={title:'Contact',description:'Contact The Real Art for artwork, artist and general enquiries.',alternates:{canonical:'/contact'}};
export default async function Contact({searchParams}:{searchParams:Promise<{artwork?:string;reason?:string;message?:string;error?:string}>}){const query=await searchParams;const artworkId=/^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(query.artwork??'')?query.artwork:'';const allowed:EnquiryType[]=['artwork','artist','contact'];const type=allowed.includes(query.reason as EnquiryType)?query.reason as EnquiryType:artworkId?'artwork':'contact';return <EnquiryPage type={type} returnPath="/contact" artworkId={artworkId} search={query}/>}
