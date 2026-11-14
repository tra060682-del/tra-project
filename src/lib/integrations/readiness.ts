import 'server-only';
import {executionApproved,readProviderEnvironment,readinessState,type ReadinessState,validateProviderConfiguration} from './provider-config';

export type ReadinessItem={name:string;provider:string;mode:string;state:ReadinessState;configured:boolean;approved:boolean;operational:boolean;lastSuccessfulTest:string;lastFailure:string;detail:string};
const present=(...names:string[])=>names.every(name=>Boolean(process.env[name]));
const stateLabel=(state:ReadinessState)=>({not_configured:'Not configured',configured_disabled:'Configured but disabled',local_ready:'Local simulation ready',sandbox_connected:'Sandbox connected',sandbox_verified:'Sandbox verified',production_approved:'Production approved'}[state]);

export function integrationReadiness():ReadinessItem[]{
  const env=process.env as Record<string,string|undefined>,config=readProviderEnvironment(env),errors=validateProviderConfiguration(config,env);
  const build=(input:{name:string;provider:string;mode:string;configured:boolean;approved:boolean;verified?:boolean;detail:string}):ReadinessItem=>{const normalized=input.mode==='local'||input.mode==='sandbox'?input.mode:'disabled',state=readinessState(normalized,input.configured,input.approved,input.verified);return {...input,state,operational:normalized==='local'?input.approved:normalized==='sandbox'?input.approved&&input.verified===true:false,lastSuccessfulTest:'Not recorded',lastFailure:'Not recorded',detail:`${stateLabel(state)}. ${input.detail}`}};
  const paymentConfigured=config.paymentProvider==='razorpay'?present('RAZORPAY_KEY_ID','RAZORPAY_KEY_SECRET','RAZORPAY_WEBHOOK_SECRET'):config.paymentProvider==='stripe'?present('STRIPE_SECRET_KEY','STRIPE_WEBHOOK_SECRET'):config.paymentProvider==='local';
  const emailConfigured=config.emailProvider==='resend'?present('RESEND_API_KEY','EMAIL_FROM_ADDRESS','EMAIL_TEST_RECIPIENT_ALLOWLIST'):config.emailProvider==='ses'?present('SES_REGION','SES_ACCESS_KEY_ID','SES_SECRET_ACCESS_KEY','EMAIL_FROM_ADDRESS','EMAIL_TEST_RECIPIENT_ALLOWLIST'):config.emailProvider==='local';
  return [
    build({name:'Payment gateway',provider:config.paymentProvider,mode:config.paymentMode,configured:paymentConfigured,approved:executionApproved(config.paymentMode,config.paymentEnabled,config.paymentApproval),detail:errors.filter(value=>/PAYMENT|RAZORPAY|STRIPE/.test(value)).join(', ')||'No sandbox probe has been approved or executed.'}),
    build({name:'Transactional email',provider:config.emailProvider,mode:config.emailMode,configured:emailConfigured,approved:executionApproved(config.emailMode,config.emailEnabled,config.emailApproval),detail:errors.filter(value=>/EMAIL|RESEND|SES/.test(value)).join(', ')||'Local capture remains the default; customer delivery is disabled.'}),
    build({name:'Private storage',provider:'Cloudflare R2',mode:config.storageMode,configured:present('R2_PRIVATE_BUCKET_BINDING','R2_ACCESS_SIGNING_SECRET'),approved:executionApproved(config.storageMode,config.storageEnabled,config.storageApproval),detail:errors.filter(value=>/R2/.test(value)).join(', ')||'No R2 binding is present in committed worker configuration.'}),
    build({name:'Malware scanner',provider:'Unselected',mode:config.scannerMode,configured:present('MALWARE_SCANNER_URL','MALWARE_SCANNER_TOKEN'),approved:executionApproved(config.scannerMode,config.scannerEnabled,config.scannerApproval),detail:errors.filter(value=>/MALWARE/.test(value)).join(', ')||'Files fail closed unless a trusted clean result exists.'}),
    build({name:'Background jobs',provider:'Cloudflare Queues',mode:config.queuesMode,configured:present('TRA_EMAIL_QUEUE','TRA_NOTIFICATION_QUEUE','TRA_COMMERCE_QUEUE','TRA_DEAD_LETTER_QUEUE'),approved:executionApproved(config.queuesMode,config.queuesEnabled,config.queuesApproval),detail:'Queue bindings and consumers are not active.'}),
    build({name:'Scheduled jobs',provider:'Cloudflare Cron Triggers',mode:config.schedulesMode,configured:false,approved:executionApproved(config.schedulesMode,config.schedulesEnabled,config.schedulesApproval),detail:'No Cron Trigger is configured.'}),
    build({name:'Monitoring',provider:'Local structured logger',mode:'local',configured:true,approved:true,detail:'Local redacted logs only; no external monitoring sink.'}),
    build({name:'Certificate verification',provider:'Internal',mode:'disabled',configured:false,approved:false,detail:'Public verification remains migration and approval gated.'}),
    build({name:'Live auctions',provider:'Internal',mode:'disabled',configured:false,approved:false,detail:'Preview only; live bidding and settlement remain disabled.'}),
  ];
}
