import 'server-only';
export type ReadinessState='Not configured'|'Disabled'|'Local only'|'Awaiting approval';
export type ReadinessItem={name:string;state:ReadinessState;configured:boolean;approved:boolean;operational:false;detail:string};
const present=(...names:string[])=>names.every(name=>Boolean(process.env[name]));
const localApproved=()=>process.env.TRA_INTEGRATION_MODE==='local'&&process.env.TRA_INTEGRATION_APPROVAL==='phase6b1-local-only';
export function integrationReadiness():ReadinessItem[]{const approved=localApproved();return [
  {name:'Payment provider',configured:present('TRA_PAYMENT_PROVIDER','TRA_PAYMENT_TEST_KEY','TRA_PAYMENT_WEBHOOK_TEST_SECRET'),approved,state:!present('TRA_PAYMENT_PROVIDER','TRA_PAYMENT_TEST_KEY','TRA_PAYMENT_WEBHOOK_TEST_SECRET')?'Not configured':approved?'Local only':'Awaiting approval',operational:false,detail:'No payment intent can be created in Phase 6B.1.'},
  {name:'Email provider',configured:present('TRA_EMAIL_PROVIDER','TRA_EMAIL_TEST_TOKEN'),approved,state:!present('TRA_EMAIL_PROVIDER','TRA_EMAIL_TEST_TOKEN')?'Not configured':approved?'Local only':'Awaiting approval',operational:false,detail:'Local capture only; no outbound delivery.'},
  {name:'Private storage',configured:present('TRA_PRIVATE_STORAGE_PROVIDER','TRA_PRIVATE_STORAGE_TEST_BUCKET'),approved,state:!present('TRA_PRIVATE_STORAGE_PROVIDER','TRA_PRIVATE_STORAGE_TEST_BUCKET')?'Not configured':approved?'Local only':'Awaiting approval',operational:false,detail:'In-memory test adapter only.'},
  {name:'Malware scanner',configured:present('TRA_MALWARE_SCANNER'),approved,state:!present('TRA_MALWARE_SCANNER')?'Not configured':approved?'Local only':'Awaiting approval',operational:false,detail:'Synthetic scanner; access fails closed.'},
  {name:'Background jobs',configured:false,approved:false,state:'Disabled',operational:false,detail:'No Cloudflare Queue binding exists.'},
  {name:'Scheduled jobs',configured:false,approved:false,state:'Disabled',operational:false,detail:'No Cron Trigger exists.'},
  {name:'Monitoring',configured:true,approved:true,state:'Local only',operational:false,detail:'Structured local logger only; no external sink.'},
  {name:'Certificate verification',configured:false,approved:false,state:'Disabled',operational:false,detail:'Local synthetic verifier; public route remains disabled.'},
  {name:'Live auctions',configured:false,approved:false,state:'Disabled',operational:false,detail:'Preview only; bidding and settlement remain unavailable.'},
]}

