import {integrationCanExecute,type IntegrationMode} from './core.ts';

export type PaymentProvider='none'|'local'|'razorpay'|'stripe';
export type EmailProvider='none'|'local'|'resend'|'ses';
export type ReadinessState='not_configured'|'configured_disabled'|'local_ready'|'sandbox_connected'|'sandbox_verified'|'production_approved';

export type ProviderEnvironment={
  paymentProvider:PaymentProvider;paymentMode:IntegrationMode;paymentEnabled:boolean;paymentApproval?:string;
  emailProvider:EmailProvider;emailMode:IntegrationMode;emailEnabled:boolean;emailApproval?:string;
  storageMode:IntegrationMode;storageEnabled:boolean;storageApproval?:string;
  scannerMode:IntegrationMode;scannerEnabled:boolean;scannerApproval?:string;
  queuesMode:IntegrationMode;queuesEnabled:boolean;queuesApproval?:string;
  schedulesMode:IntegrationMode;schedulesEnabled:boolean;schedulesApproval?:string;
};

const mode=(value:string|undefined):IntegrationMode=>value==='local'||value==='sandbox'?value:'disabled';
const enabled=(value:string|undefined)=>value==='true';
const paymentProvider=(value:string|undefined):PaymentProvider=>value==='local'||value==='razorpay'||value==='stripe'?value:'none';
const emailProvider=(value:string|undefined):EmailProvider=>value==='local'||value==='resend'||value==='ses'?value:'none';

export function readProviderEnvironment(env:Record<string,string|undefined>):ProviderEnvironment{return {
  paymentProvider:paymentProvider(env.PAYMENT_PROVIDER),paymentMode:mode(env.PAYMENT_MODE),paymentEnabled:enabled(env.PAYMENT_SANDBOX_ENABLED)||env.PAYMENT_MODE==='local',paymentApproval:env.PAYMENT_ACTIVATION_APPROVAL,
  emailProvider:emailProvider(env.EMAIL_PROVIDER),emailMode:mode(env.EMAIL_MODE),emailEnabled:enabled(env.EMAIL_SANDBOX_ENABLED)||env.EMAIL_MODE==='local',emailApproval:env.EMAIL_ACTIVATION_APPROVAL,
  storageMode:mode(env.PRIVATE_STORAGE_MODE),storageEnabled:enabled(env.PRIVATE_STORAGE_SANDBOX_ENABLED)||env.PRIVATE_STORAGE_MODE==='local',storageApproval:env.PRIVATE_STORAGE_ACTIVATION_APPROVAL,
  scannerMode:mode(env.MALWARE_SCANNER_MODE),scannerEnabled:enabled(env.MALWARE_SCANNER_SANDBOX_ENABLED)||env.MALWARE_SCANNER_MODE==='local',scannerApproval:env.MALWARE_SCANNER_ACTIVATION_APPROVAL,
  queuesMode:mode(env.BACKGROUND_JOBS_MODE),queuesEnabled:enabled(env.CLOUDFLARE_QUEUES_ENABLED)||env.BACKGROUND_JOBS_MODE==='local',queuesApproval:env.QUEUES_ACTIVATION_APPROVAL,
  schedulesMode:mode(env.SCHEDULED_JOBS_MODE),schedulesEnabled:enabled(env.CLOUDFLARE_CRONS_ENABLED)||env.SCHEDULED_JOBS_MODE==='local',schedulesApproval:env.SCHEDULES_ACTIVATION_APPROVAL,
}}

export function validateProviderConfiguration(config:ProviderEnvironment,env:Record<string,string|undefined>){
  const errors:string[]=[];
  if(config.paymentMode==='sandbox'){
    if(config.paymentProvider==='razorpay'&&(!env.RAZORPAY_KEY_ID||!env.RAZORPAY_KEY_SECRET||!env.RAZORPAY_WEBHOOK_SECRET))errors.push('RAZORPAY_CONFIGURATION_INCOMPLETE');
    if(config.paymentProvider==='stripe'&&(!env.STRIPE_SECRET_KEY||!env.STRIPE_WEBHOOK_SECRET))errors.push('STRIPE_CONFIGURATION_INCOMPLETE');
    if(config.paymentProvider==='none'||config.paymentProvider==='local')errors.push('PAYMENT_SANDBOX_PROVIDER_REQUIRED');
  }
  if(config.emailMode==='sandbox'){
    if(!env.EMAIL_FROM_ADDRESS)errors.push('EMAIL_FROM_ADDRESS_REQUIRED');
    if(config.emailProvider==='resend'&&!env.RESEND_API_KEY)errors.push('RESEND_CONFIGURATION_INCOMPLETE');
    if(config.emailProvider==='ses'&&(!env.SES_REGION||!env.SES_ACCESS_KEY_ID||!env.SES_SECRET_ACCESS_KEY))errors.push('SES_CONFIGURATION_INCOMPLETE');
    if(config.emailProvider==='none'||config.emailProvider==='local')errors.push('EMAIL_SANDBOX_PROVIDER_REQUIRED');
    if(!env.EMAIL_TEST_RECIPIENT_ALLOWLIST)errors.push('EMAIL_TEST_ALLOWLIST_REQUIRED');
  }
  if(config.storageMode==='sandbox'&&!env.R2_PRIVATE_BUCKET_BINDING)errors.push('R2_BINDING_REQUIRED');
  if(config.scannerMode==='sandbox'&&(!env.MALWARE_SCANNER_URL||!env.MALWARE_SCANNER_TOKEN))errors.push('MALWARE_SCANNER_CONFIGURATION_INCOMPLETE');
  return errors;
}

export function executionApproved(mode:IntegrationMode,featureEnabled:boolean,approvalReference?:string){return integrationCanExecute({mode,featureEnabled,approvalReference})}

export function readinessState(mode:IntegrationMode,configured:boolean,approved:boolean,verified=false):ReadinessState{
  if(!configured)return 'not_configured';
  if(mode==='disabled'||!approved)return 'configured_disabled';
  if(mode==='local')return 'local_ready';
  return verified?'sandbox_verified':'sandbox_connected';
}

export function safeConfigurationSummary(config:ProviderEnvironment,errors:string[]){return {
  payment:{provider:config.paymentProvider,mode:config.paymentMode,enabled:config.paymentEnabled,approved:executionApproved(config.paymentMode,config.paymentEnabled,config.paymentApproval)},
  email:{provider:config.emailProvider,mode:config.emailMode,enabled:config.emailEnabled,approved:executionApproved(config.emailMode,config.emailEnabled,config.emailApproval)},
  privateStorage:{provider:'cloudflare-r2',mode:config.storageMode,enabled:config.storageEnabled,approved:executionApproved(config.storageMode,config.storageEnabled,config.storageApproval)},
  malwareScanner:{provider:'unselected',mode:config.scannerMode,enabled:config.scannerEnabled,approved:executionApproved(config.scannerMode,config.scannerEnabled,config.scannerApproval)},
  queues:{provider:'cloudflare-queues',mode:config.queuesMode,enabled:config.queuesEnabled,approved:executionApproved(config.queuesMode,config.queuesEnabled,config.queuesApproval)},
  schedules:{provider:'cloudflare-cron',mode:config.schedulesMode,enabled:config.schedulesEnabled,approved:executionApproved(config.schedulesMode,config.schedulesEnabled,config.schedulesApproval)},
  errors:[...errors],
};}
