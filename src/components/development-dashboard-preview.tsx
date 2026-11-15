import Link from 'next/link';
import {DashboardLayout,DashboardMetrics} from '@/components/dashboard-layout';
import {DashboardHeading,DashboardSection,DataTable,DisabledAction,StatusBadge} from '@/components/dashboard-kit';
import {dashboardPreviewFixtures} from '@/data/dashboard-preview-fixtures';
import {dashboardPreviewSlugs,type DashboardPreviewSlug} from '@/lib/dashboard-preview';

const labels:Record<DashboardPreviewSlug,string>={'super-admin':'Super Admin',admin:'Admin',artist:'Artist Studio',intermediary:'Intermediary',collector:'Collector'};

export function DevelopmentDashboardPreview({slug}:{slug:DashboardPreviewSlug}){
 const fixture=dashboardPreviewFixtures[slug];
 const navigation=dashboardPreviewSlugs.map(item=>({label:labels[item],href:`/dev/dashboard-preview/${item}`}));
 return <main data-dashboard-preview="synthetic" data-preview-role={slug}>
  <div className="development-demo-banner" role="status"><strong>DEVELOPMENT DEMO</strong><span>Synthetic records only · read-only · no Supabase, payments, uploads or provider actions</span><Link href="/dev/dashboard-preview">All previews</Link></div>
  <DashboardLayout role={fixture.role} name="tRA synthetic preview" active={labels[slug]} items={navigation} previewMode>
   <nav className="preview-dashboard-switcher" aria-label="Development dashboard previews">{navigation.map(item=><Link key={item.href} href={item.href} aria-current={item.label===labels[slug]?'page':undefined}>{item.label}</Link>)}</nav>
   <DashboardHeading eyebrow={fixture.eyebrow} title={fixture.title} description={fixture.description}/>
   <DashboardMetrics items={fixture.metrics}/>
   {fixture.sections.map(section=><DashboardSection key={section.title} title={section.title} description={section.description}>
    <DataTable caption={section.title} headers={section.headers} rows={section.rows.map(row=>row.cells.map((cell,index)=>index===2||index===3?<StatusBadge key={`${cell}-${index}`} tone={row.tone}>{cell}</StatusBadge>:cell))}/>
    <div className="preview-disabled-actions" aria-label={`${section.title} disabled controls`}>{section.actions.map(action=><DisabledAction key={action} reason="Disabled in DEVELOPMENT DEMO. No write, provider call or privileged operation is available.">{action}</DisabledAction>)}</div>
   </DashboardSection>)}
  </DashboardLayout>
 </main>;
}
