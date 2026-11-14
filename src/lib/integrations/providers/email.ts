import {IntegrationError} from '../core.ts';
import type {EmailDelivery,EmailGateway,EmailMessage} from '../email.ts';
import {bearerAuthorization,providerFetch,type FetchLike} from './http.ts';

type Preferences={emailEnabled:boolean;suppressed:boolean};
type CommonEmailConfig={from:string;replyTo?:string;allowedRecipients:string[];enabled:boolean;approvalReference?:string;timeoutMs?:number};
export type ResendConfig=CommonEmailConfig&{apiKey:string;baseUrl?:string};
export type SesConfig=CommonEmailConfig&{region:string;accessKeyId:string;secretAccessKey:string;sessionToken?:string;baseUrl?:string};

function assertDeliveryAllowed(message:EmailMessage,preferences:Preferences,config:CommonEmailConfig){
  if(!config.enabled||config.approvalReference!=='phase6b2-sandbox-approved')throw new IntegrationError('EMAIL_PROVIDER_DISABLED');
  if(preferences.suppressed)throw new IntegrationError('RECIPIENT_SUPPRESSED');
  if(message.category==='optional'&&!preferences.emailEnabled)throw new IntegrationError('PREFERENCE_DISABLED');
  if(!config.allowedRecipients.map(value=>value.toLowerCase()).includes(message.to.toLowerCase()))throw new IntegrationError('RECIPIENT_NOT_ALLOWLISTED');
}

export class ResendEmailGateway implements EmailGateway{
  private sent=new Map<string,EmailDelivery>();
  private config:ResendConfig;private fetcher:FetchLike;
  constructor(config:ResendConfig,fetcher:FetchLike=fetch){this.config=config;this.fetcher=fetcher;if(!config.apiKey)throw new IntegrationError('RESEND_CONFIGURATION_INCOMPLETE')}
  async send(message:EmailMessage,preferences:Preferences){assertDeliveryAllowed(message,preferences,this.config);const prior=this.sent.get(message.idempotencyKey);if(prior)return prior;const response=await providerFetch(this.fetcher,`${this.config.baseUrl??'https://api.resend.com'}/emails`,{method:'POST',headers:{Authorization:bearerAuthorization(this.config.apiKey),'Content-Type':'application/json','Idempotency-Key':message.idempotencyKey},body:JSON.stringify({from:this.config.from,to:[message.to],subject:message.subject,html:message.html,text:message.text,reply_to:this.config.replyTo})},this.config.timeoutMs);const value=await response.json() as {id?:string};if(!value.id)throw new IntegrationError('RESEND_INVALID_RESPONSE');const delivery={id:value.id,status:'accepted',simulated:false} as const;this.sent.set(message.idempotencyKey,delivery);return delivery}
}

const encoder=new TextEncoder();
const hex=(bytes:ArrayBuffer|Uint8Array)=>[...new Uint8Array(bytes instanceof Uint8Array?bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength):bytes)].map(value=>value.toString(16).padStart(2,'0')).join('');
async function sha256(value:string){return crypto.subtle.digest('SHA-256',encoder.encode(value))}
async function hmac(key:ArrayBuffer|Uint8Array,value:string){const normalized=new Uint8Array(Array.from(new Uint8Array(key instanceof Uint8Array?key.buffer:key)));const imported=await crypto.subtle.importKey('raw',normalized,{name:'HMAC',hash:'SHA-256'},false,['sign']);return crypto.subtle.sign('HMAC',imported,encoder.encode(value))}
async function awsSignature(secret:string,date:string,region:string,stringToSign:string){const kDate=await hmac(encoder.encode(`AWS4${secret}`),date),kRegion=await hmac(kDate,region),kService=await hmac(kRegion,'ses'),kSigning=await hmac(kService,'aws4_request');return hex(await hmac(kSigning,stringToSign))}

export async function signSesRequest(input:{body:string;region:string;accessKeyId:string;secretAccessKey:string;sessionToken?:string;now:Date;host?:string}){
  const host=input.host??`email.${input.region}.amazonaws.com`,amzDate=input.now.toISOString().replace(/[:-]|\.\d{3}/g,''),date=amzDate.slice(0,8),payloadHash=hex(await sha256(input.body));
  const tokenHeader=input.sessionToken?`x-amz-security-token:${input.sessionToken}\n`:'';const signedHeaders=input.sessionToken?'content-type;host;x-amz-date;x-amz-security-token':'content-type;host;x-amz-date';
  const canonicalHeaders=`content-type:application/json\nhost:${host}\nx-amz-date:${amzDate}\n${tokenHeader}`;const canonicalRequest=`POST\n/v2/email/outbound-emails\n\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;
  const scope=`${date}/${input.region}/ses/aws4_request`,stringToSign=`AWS4-HMAC-SHA256\n${amzDate}\n${scope}\n${hex(await sha256(canonicalRequest))}`,signature=await awsSignature(input.secretAccessKey,date,input.region,stringToSign);
  return {Authorization:`AWS4-HMAC-SHA256 Credential=${input.accessKeyId}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,'Content-Type':'application/json','X-Amz-Date':amzDate,...(input.sessionToken?{'X-Amz-Security-Token':input.sessionToken}:{})};
}

export class SesEmailGateway implements EmailGateway{
  private sent=new Map<string,EmailDelivery>();
  private config:SesConfig;private fetcher:FetchLike;private now:()=>Date;
  constructor(config:SesConfig,fetcher:FetchLike=fetch,now=()=>new Date()){this.config=config;this.fetcher=fetcher;this.now=now;if(!config.region||!config.accessKeyId||!config.secretAccessKey)throw new IntegrationError('SES_CONFIGURATION_INCOMPLETE')}
  async send(message:EmailMessage,preferences:Preferences){assertDeliveryAllowed(message,preferences,this.config);const prior=this.sent.get(message.idempotencyKey);if(prior)return prior;const body=JSON.stringify({FromEmailAddress:this.config.from,Destination:{ToAddresses:[message.to]},Content:{Simple:{Subject:{Data:message.subject,Charset:'UTF-8'},Body:{Html:{Data:message.html,Charset:'UTF-8'},Text:{Data:message.text,Charset:'UTF-8'}}}},ReplyToAddresses:this.config.replyTo?[this.config.replyTo]:undefined,EmailTags:[{Name:'tra-idempotency',Value:message.idempotencyKey.replace(/[^A-Za-z0-9_-]/g,'-').slice(0,256)}]});const host=`email.${this.config.region}.amazonaws.com`,headers=await signSesRequest({body,region:this.config.region,accessKeyId:this.config.accessKeyId,secretAccessKey:this.config.secretAccessKey,sessionToken:this.config.sessionToken,now:this.now(),host});const response=await providerFetch(this.fetcher,this.config.baseUrl??`https://${host}/v2/email/outbound-emails`,{method:'POST',headers,body},this.config.timeoutMs);const value=await response.json() as {MessageId?:string};if(!value.MessageId)throw new IntegrationError('SES_INVALID_RESPONSE');const delivery={id:value.MessageId,status:'accepted',simulated:false} as const;this.sent.set(message.idempotencyKey,delivery);return delivery}
}
