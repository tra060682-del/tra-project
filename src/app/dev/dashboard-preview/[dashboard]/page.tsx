import {notFound} from 'next/navigation';
import {DevelopmentDashboardPreview} from '@/components/development-dashboard-preview';
import {isDashboardPreviewSlug} from '@/lib/dashboard-preview';

export default async function DashboardPreviewPage({params}:{params:Promise<{dashboard:string}>}){
 const {dashboard}=await params;
 if(!isDashboardPreviewSlug(dashboard))notFound();
 return <DevelopmentDashboardPreview slug={dashboard}/>;
}
