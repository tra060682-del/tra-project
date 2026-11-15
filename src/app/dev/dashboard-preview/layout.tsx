import type {Metadata} from 'next';
import {requireDevelopmentDashboardPreview} from '@/lib/dashboard-preview';

export const metadata:Metadata={title:'Dashboard development demo',robots:{index:false,follow:false,nocache:true}};

export default function DashboardPreviewLayout({children}:{children:React.ReactNode}){
 requireDevelopmentDashboardPreview();
 return children;
}
