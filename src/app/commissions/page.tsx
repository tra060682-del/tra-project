import type {Metadata} from 'next';import {EnquiryPage} from '@/components/enquiry-page';
export const metadata:Metadata={title:'Custom Commissions',description:'Discuss a custom artwork commission with tRA.',alternates:{canonical:'/commissions'}};
export default async function Page({searchParams}:{searchParams:Promise<{message?:string;error?:string}>}){return <EnquiryPage type="commission" returnPath="/commissions" search={await searchParams}/>}
