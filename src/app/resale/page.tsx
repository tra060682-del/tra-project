import type {Metadata} from 'next';import {EnquiryPage} from '@/components/enquiry-page';
export const metadata:Metadata={title:'Resale Enquiries',description:'Submit an artwork resale enquiry for manual tRA review.',alternates:{canonical:'/resale'}};
export default async function Page({searchParams}:{searchParams:Promise<{message?:string;error?:string}>}){return <EnquiryPage type="resale" returnPath="/resale" search={await searchParams}/>}
