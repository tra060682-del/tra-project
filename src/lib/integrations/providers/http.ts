import {IntegrationError,retryClassification,withTimeout} from '../core.ts';

export type FetchLike=(input:string|URL|Request,init?:RequestInit)=>Promise<Response>;

export async function providerFetch(fetcher:FetchLike,url:string,init:RequestInit,timeoutMs=10_000){
  const response=await withTimeout(signal=>fetcher(url,{...init,signal}),timeoutMs,init.signal??undefined);
  if(!response.ok){
    const status=response.status;
    throw new IntegrationError(`PROVIDER_HTTP_${status}`,retryClassification(status),'Provider request failed');
  }
  return response;
}

export function basicAuthorization(id:string,secret:string){return `Basic ${btoa(`${id}:${secret}`)}`}
export function bearerAuthorization(secret:string){return `Bearer ${secret}`}

const encoder=new TextEncoder();
export async function hmacHex(secret:string,payload:string){const imported=await crypto.subtle.importKey('raw',encoder.encode(secret),{name:'HMAC',hash:'SHA-256'},false,['sign']);const signature=await crypto.subtle.sign('HMAC',imported,encoder.encode(payload));return [...new Uint8Array(signature)].map(value=>value.toString(16).padStart(2,'0')).join('')}
export function constantTimeEqual(left:string,right:string){if(left.length!==right.length)return false;let difference=0;for(let index=0;index<left.length;index++)difference|=left.charCodeAt(index)^right.charCodeAt(index);return difference===0}
