import Link from 'next/link';
import {dashboardPreviewSlugs} from '@/lib/dashboard-preview';

const labels={
 'super-admin':{title:'Super Admin',body:'Platform governance, access inspection and operational controls.'},
 admin:{title:'Admin',body:'Artist, artwork, enquiry and content review queues.'},
 artist:{title:'Artist Studio',body:'Profile, artworks, agreements, enquiries and sales visibility.'},
 intermediary:{title:'Intermediary',body:'Consent-bound artist representation and delegated scope.'},
 collector:{title:'Collector',body:'Saved artworks, offers, orders, shipping and certificates.'}
} as const;

export default function DashboardPreviewIndex(){
 return <main className="dashboard-preview-index" data-dashboard-preview="synthetic"><div className="development-demo-banner" role="status"><strong>DEVELOPMENT DEMO</strong><span>Synthetic records only · all operations disabled</span></div><header><p className="eyebrow">DASHBOARD VISUAL REVIEW</p><h1>Five workspaces. No privileged access.</h1><p>Choose a role to inspect the approved tRA dashboard foundation. These development-only pages do not authenticate as a real user, query Supabase, or expose application APIs.</p></header><section aria-label="Dashboard previews">{dashboardPreviewSlugs.map(slug=><Link href={`/dev/dashboard-preview/${slug}`} key={slug}><span>Development demo</span><h2>{labels[slug].title}</h2><p>{labels[slug].body}</p><strong>Open preview →</strong></Link>)}</section></main>;
}
