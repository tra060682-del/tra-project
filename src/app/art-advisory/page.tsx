import type {Metadata} from 'next';import {EnquiryPage} from '@/components/enquiry-page';
export const metadata:Metadata={title:'Art Advisory',description:'Request personal art guidance from tRA.',alternates:{canonical:'/art-advisory'}};
export default async function Page({searchParams}:{searchParams:Promise<{message?:string;error?:string}>}){return <EnquiryPage type="advisory" returnPath="/art-advisory" search={await searchParams}/>}
