export const emailTemplateNames=['welcome','artist_registration','artist_onboarding_submission','artist_approval','artist_rejection','artwork_submission','artwork_approval','artwork_rejection','buyer_enquiry','offer_received','counteroffer_received','order_confirmation','payment_confirmation','shipping_update','certificate_issued','invitation','password_reset_notification','account_suspension','security_alert'] as const;
export type EmailTemplateName=typeof emailTemplateNames[number];
export type EmailMessage={to:string;template:EmailTemplateName;subject:string;html:string;text:string;idempotencyKey:string;category:'security'|'transactional'|'optional'};
export type EmailDelivery={id:string;status:'captured'|'accepted'|'suppressed'|'failed';simulated:boolean;reason?:string};
const escape=(value:string)=>value.replace(/[&<>"']/g,character=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[character]!));
const titles:Record<EmailTemplateName,string>={welcome:'Welcome to The Real Art',artist_registration:'Artist registration received',artist_onboarding_submission:'Your artist application was submitted',artist_approval:'Your artist profile was approved',artist_rejection:'Your artist application needs attention',artwork_submission:'Artwork submission received',artwork_approval:'Artwork approved',artwork_rejection:'Artwork review update',buyer_enquiry:'We received your enquiry',offer_received:'New artwork offer',counteroffer_received:'Counteroffer received',order_confirmation:'Order confirmation',payment_confirmation:'Payment confirmation',shipping_update:'Shipping update',certificate_issued:'Certificate of Authenticity issued',invitation:'Your tRA invitation',password_reset_notification:'Password reset requested',account_suspension:'Account access suspended',security_alert:'Security alert'};

export function renderEmail(input:{template:EmailTemplateName;recipientName:string;summary:string;actionUrl?:string;reference?:string;idempotencyKey:string;to:string;category?:EmailMessage['category']}):EmailMessage{
  if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.to))throw new Error('INVALID_RECIPIENT');
  const title=titles[input.template],name=escape(input.recipientName||'tRA member'),summary=escape(input.summary),reference=input.reference?` Reference: ${escape(input.reference)}.`:'';
  const action=input.actionUrl?`<p><a href="${escape(input.actionUrl)}" style="background:#171512;color:#fff;padding:12px 18px;text-decoration:none;display:inline-block">View securely</a></p>`:'';
  const html=`<!doctype html><html lang="en"><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title></head><body style="margin:0;background:#f7f2e8;color:#171512;font-family:Arial,sans-serif"><main style="max-width:640px;margin:auto;padding:32px"><p style="letter-spacing:.16em;color:#8b6b2e">tRA — THE REAL ART</p><h1 style="font-family:Georgia,serif">${title}</h1><p>Hello ${name},</p><p>${summary}${reference}</p>${action}<p>For your security, tRA will never ask for your password or payment credentials by email.</p></main></body></html>`;
  const text=`tRA — The Real Art\n\n${title}\n\nHello ${input.recipientName||'tRA member'},\n\n${input.summary}${input.reference?` Reference: ${input.reference}.`:''}${input.actionUrl?`\n\nView securely: ${input.actionUrl}`:''}\n\nFor your security, tRA will never ask for your password or payment credentials by email.`;
  return {to:input.to.toLowerCase(),template:input.template,subject:title,html,text,idempotencyKey:input.idempotencyKey,category:input.category??(input.template==='security_alert'||input.template==='account_suspension'||input.template==='password_reset_notification'?'security':'transactional')};
}

export interface EmailGateway{send(message:EmailMessage,preferences:{emailEnabled:boolean;suppressed:boolean}):Promise<EmailDelivery>}
export class LocalCaptureEmailGateway implements EmailGateway{
  readonly messages:EmailMessage[]=[];
  async send(message:EmailMessage,preferences:{emailEnabled:boolean;suppressed:boolean}){
    if(preferences.suppressed)return {id:`mail_local_${this.messages.length+1}`,status:'suppressed',simulated:true,reason:'RECIPIENT_SUPPRESSED'} as const;
    if(message.category==='optional'&&!preferences.emailEnabled)return {id:`mail_local_${this.messages.length+1}`,status:'suppressed',simulated:true,reason:'PREFERENCE_DISABLED'} as const;
    const existing=this.messages.find(item=>item.idempotencyKey===message.idempotencyKey);
    if(existing)return {id:`mail_local_${this.messages.indexOf(existing)+1}`,status:'captured',simulated:true} as const;
    this.messages.push(structuredClone(message));
    return {id:`mail_local_${this.messages.length}`,status:'captured',simulated:true} as const;
  }
}
