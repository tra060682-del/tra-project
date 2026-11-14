import {DashboardLayout} from '@/components/dashboard-layout';
import {DashboardHeading,DashboardSection,DataTable,DisabledAction,StatusBadge} from '@/components/dashboard-kit';
import {requirePermission} from '@/lib/auth';
import {integrationReadiness} from '@/lib/integrations/readiness';

export default async function IntegrationReadiness(){
  const {user}=await requirePermission('integrations.manage'),items=integrationReadiness();
  return <DashboardLayout role="Super Admin" name={user.email||'Super Admin'} active="Integrations" items={[{label:'Overview',href:'/admin'},{label:'Settings',href:'/admin/settings'},{label:'Integrations',href:'/admin/integrations'},{label:'Audit',href:'/admin/audit'}]}>
    <DashboardHeading eyebrow="SUPER ADMIN · READ ONLY" title="Integration operations" description="Server-side diagnostics report provider, mode, configuration and approval independently. Secret values are never rendered and no browser control can activate a provider."/>
    <div className="ui-notice"><strong>External traffic is disabled.</strong> Configuration alone cannot mark an integration operational. Sandbox verification requires an approved, recorded probe.</div>
    <DashboardSection title="Provider status"><DataTable caption="Integration operations" headers={['Integration','Provider','Mode','Status','Approved','Operational','Last success','Last failure','Boundary']} rows={items.map(item=>[item.name,item.provider,item.mode,<StatusBadge key="s" tone={item.state==='sandbox_verified'?'success':item.state==='not_configured'?'danger':'warning'}>{item.state.replaceAll('_',' ')}</StatusBadge>,item.approved?'Yes':'No',item.operational?'Yes':'No',item.lastSuccessfulTest,item.lastFailure,item.detail])}/></DashboardSection>
    <DashboardSection title="Configuration controls"><div className="dashboard-feature-grid"><DisabledAction reason="Provider configuration is server-only and approval-gated.">Configure provider</DisabledAction><DisabledAction reason="Phase 6B.2 does not authorise sandbox traffic.">Connect sandbox</DisabledAction><DisabledAction reason="Production activation requires a separate approval and release procedure.">Promote configuration</DisabledAction></div></DashboardSection>
  </DashboardLayout>;
}
