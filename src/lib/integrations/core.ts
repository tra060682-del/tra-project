export type IntegrationMode='disabled'|'local';
export type RetryClass='never'|'immediate'|'transient'|'rate_limited';
export type IntegrationOutcome='success'|'rejected'|'failed'|'simulated';

export class IntegrationError extends Error{
  readonly code:string;readonly retry:RetryClass;readonly safeMessage:string;
  constructor(code:string,retry:RetryClass='never',safeMessage='Integration operation failed'){super(code);this.name='IntegrationError';this.code=code;this.retry=retry;this.safeMessage=safeMessage}
}

export type IntegrationContext={correlationId:string;requestId:string;now?:Date;signal?:AbortSignal};
export type ProviderResult<T>={outcome:IntegrationOutcome;provider:'local';simulated:true;data:T;providerReference?:string};

export function assertSafeMinorUnits(value:number,label='amount'){if(!Number.isSafeInteger(value)||value<0)throw new IntegrationError(`INVALID_${label.toUpperCase()}`);return value}
export function assertCurrency(value:string){if(!/^[A-Z]{3}$/.test(value))throw new IntegrationError('INVALID_CURRENCY');return value}
export function assertIdempotencyKey(value:string){if(!/^[A-Za-z0-9:_-]{8,128}$/.test(value))throw new IntegrationError('INVALID_IDEMPOTENCY_KEY');return value}
export function retryClassification(status:number):RetryClass{if(status===408||status===425||status===429)return status===429?'rate_limited':'transient';if(status>=500)return 'transient';return 'never'}

export function withTimeout<T>(operation:(signal:AbortSignal)=>Promise<T>,milliseconds:number,outer?:AbortSignal){
  if(!Number.isInteger(milliseconds)||milliseconds<1||milliseconds>60_000)throw new IntegrationError('INVALID_TIMEOUT');
  const controller=new AbortController();const timer=setTimeout(()=>controller.abort('timeout'),milliseconds);
  const abort=()=>controller.abort(outer?.reason);outer?.addEventListener('abort',abort,{once:true});
  return operation(controller.signal).catch(error=>{if(controller.signal.aborted)throw new IntegrationError('INTEGRATION_TIMEOUT','transient');throw error}).finally(()=>{clearTimeout(timer);outer?.removeEventListener('abort',abort)});
}

export type IntegrationConfig={mode:IntegrationMode;featureEnabled:boolean;approvalReference?:string};
export function integrationCanExecute(config:IntegrationConfig){return config.mode==='local'&&config.featureEnabled&&config.approvalReference==='phase6b1-local-only'}

