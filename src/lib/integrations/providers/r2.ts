import {IntegrationError} from '../core.ts';
import {validateMagicBytes,validatePrivateUpload,type PrivateObject,type UploadInput} from '../storage.ts';
import {constantTimeEqual,hmacHex} from './http.ts';

export interface R2BucketLike{
  put(key:string,value:Uint8Array,options?:{httpMetadata?:{contentType?:string};customMetadata?:Record<string,string>}):Promise<unknown>;
  get(key:string):Promise<{body:ReadableStream;customMetadata?:Record<string,string>}|null>;
  head(key:string):Promise<unknown|null>;
  delete(key:string):Promise<void>;
}
export type R2Config={enabled:boolean;approvalReference?:string;bindingName:string;accessSigningSecret:string;accessPath?:string};
const digestHex=async(bytes:Uint8Array)=>[...new Uint8Array(await crypto.subtle.digest('SHA-256',new Uint8Array(Array.from(bytes))))].map(value=>value.toString(16).padStart(2,'0')).join('');

export class R2PrivateStorage{
  private objects=new Map<string,PrivateObject>();private uploadTokens=new Map<string,{objectId:string;expiresAt:number}>();readonly audit:{objectId:string;actorUserId:string;action:string;at:number}[]=[];
  private bucket:R2BucketLike;private config:R2Config;private now:()=>number;
  constructor(bucket:R2BucketLike,config:R2Config,now=()=>Date.now()){this.bucket=bucket;this.config=config;this.now=now;if(!config.enabled||config.approvalReference!=='phase6b2-sandbox-approved')throw new IntegrationError('R2_DISABLED');if(!config.bindingName||config.accessSigningSecret.length<32)throw new IntegrationError('R2_CONFIGURATION_INCOMPLETE')}
  async initiateUpload(input:UploadInput){validatePrivateUpload(input);const id=`obj_r2_${crypto.randomUUID()}`,storageKey=`private/${input.purpose}/${input.ownerUserId}/${id}`,object:PrivateObject={id,ownerUserId:input.ownerUserId,purpose:input.purpose,filename:input.filename,mimeType:input.mimeType,size:input.size,sha256:input.sha256,state:'pending_upload',storageKey};this.objects.set(id,object);const uploadToken=crypto.randomUUID(),expiresAt=this.now()+300_000;this.uploadTokens.set(uploadToken,{objectId:id,expiresAt});this.audit.push({objectId:id,actorUserId:input.actorUserId,action:'upload_initiated',at:this.now()});return {object:{...object},uploadToken,expiresAt,simulated:false as const}}
  async completeUpload(uploadToken:string,actorUserId:string,bytes:Uint8Array){const claim=this.uploadTokens.get(uploadToken);if(!claim||claim.expiresAt<this.now())throw new IntegrationError('UPLOAD_TOKEN_INVALID');const object=this.requireOwned(claim.objectId,actorUserId);if(object.state!=='pending_upload'||bytes.byteLength!==object.size||!validateMagicBytes(object.mimeType,bytes)||await digestHex(bytes)!==object.sha256)throw new IntegrationError('FILE_CONTENT_MISMATCH');await this.bucket.put(object.storageKey,bytes,{httpMetadata:{contentType:object.mimeType},customMetadata:{objectId:object.id,ownerUserId:object.ownerUserId,purpose:object.purpose,state:'quarantined',sha256:object.sha256}});object.state='quarantined';this.uploadTokens.delete(uploadToken);this.audit.push({objectId:object.id,actorUserId,action:'upload_quarantined',at:this.now()});return {...object}}
  applyScan(id:string,state:'clean'|'infected'){const object=this.objects.get(id);if(!object||object.state!=='quarantined')throw new IntegrationError('OBJECT_NOT_QUARANTINED');object.state=state;return {...object}}
  async signedAccess(id:string,actorUserId:string,ttlSeconds:number){const object=this.requireOwned(id,actorUserId);if(object.state!=='clean')throw new IntegrationError('OBJECT_ACCESS_DENIED');if(!Number.isInteger(ttlSeconds)||ttlSeconds<1||ttlSeconds>300)throw new IntegrationError('INVALID_ACCESS_TTL');if(!await this.bucket.head(object.storageKey))throw new IntegrationError('OBJECT_NOT_FOUND');const expiresAt=this.now()+ttlSeconds*1000,payload=`${id}.${actorUserId}.${expiresAt}`,signature=await hmacHex(this.config.accessSigningSecret,payload);this.audit.push({objectId:id,actorUserId,action:'signed_access',at:this.now()});return {url:`${this.config.accessPath??'/api/private-media/access'}?object=${encodeURIComponent(id)}&expires=${expiresAt}&signature=${signature}`,expiresAt,simulated:false as const}}
  async verifyAccessToken(input:{objectId:string;actorUserId:string;expiresAt:number;signature:string}){if(input.expiresAt<this.now())return false;const expected=await hmacHex(this.config.accessSigningSecret,`${input.objectId}.${input.actorUserId}.${input.expiresAt}`);return constantTimeEqual(expected,input.signature)}
  async revoke(id:string,actorUserId:string){const object=this.requireOwned(id,actorUserId);object.state='revoked';await this.bucket.delete(object.storageKey);this.audit.push({objectId:id,actorUserId,action:'revoked',at:this.now()})}
  private requireOwned(id:string,actorUserId:string){const object=this.objects.get(id);if(!object||object.ownerUserId!==actorUserId)throw new IntegrationError('STORAGE_OWNERSHIP_DENIED');return object}
}
