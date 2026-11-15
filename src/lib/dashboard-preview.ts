import 'server-only';
import {notFound} from 'next/navigation';

export const dashboardPreviewSlugs=['super-admin','admin','artist','intermediary','collector'] as const;
export type DashboardPreviewSlug=(typeof dashboardPreviewSlugs)[number];

export function requireDevelopmentDashboardPreview(){
 if(process.env.NODE_ENV!=='development')notFound();
}

export function isDashboardPreviewSlug(value:string):value is DashboardPreviewSlug{
 return dashboardPreviewSlugs.includes(value as DashboardPreviewSlug);
}
