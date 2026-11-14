import type {Metadata} from 'next';import {EnquiryPage} from '@/components/enquiry-page';
export const metadata:Metadata={title:'Corporate Art',description:'Discuss a corporate art project with tRA.',alternates:{canonical:'/corporate-art'}};
export default async function Page({searchParams}:{searchParams:Promise<{message?:string;error?:string}>}){return <EnquiryPage type="corporate" returnPath="/corporate-art" search={await searchParams}/>}
