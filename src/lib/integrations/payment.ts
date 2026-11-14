export type Money={amountMinor:number;currency:string};
export type PaymentState='created'|'requires_action'|'processing'|'succeeded'|'failed'|'cancelled'|'partially_refunded'|'refunded';
export type RefundState='requested'|'processing'|'succeeded'|'failed';
export type PaymentIntent={id:string;orderReference:string;money:Money;state:PaymentState;idempotencyKey:string;providerReference:string;simulated:boolean};
export type Refund={id:string;paymentId:string;money:Money;state:RefundState;idempotencyKey:string;providerReference:string;simulated:boolean};
export type PaymentEvent={id:string;createdAt:number;type:'payment.processing'|'payment.succeeded'|'payment.failed'|'refund.succeeded'|'refund.failed';paymentId:string;orderReference:string;amountMinor:number;currency:string;refundId?:string};
export type WebhookRequest={rawBody:string;signature:string|null;timestamp:string|null;secret:string;now:number;toleranceMs?:number};
export type WebhookVerification={valid:true;event:PaymentEvent}|{valid:false;code:'MISSING_SIGNATURE'|'INVALID_TIMESTAMP'|'EXPIRED_TIMESTAMP'|'INVALID_SIGNATURE'|'INVALID_PAYLOAD'};

const encoder=new TextEncoder();
const money=(value:Money)=>{if(!Number.isSafeInteger(value.amountMinor)||value.amountMinor<=0)throw new Error('INVALID_AMOUNT');if(!/^[A-Z]{3}$/.test(value.currency))throw new Error('INVALID_CURRENCY');return value};
const key=(value:string)=>{if(!/^[A-Za-z0-9:_-]{8,128}$/.test(value))throw new Error('INVALID_IDEMPOTENCY_KEY');return value};
const hex=(data:ArrayBuffer)=>[...new Uint8Array(data)].map(value=>value.toString(16).padStart(2,'0')).join('');
async function hmac(secret:string,payload:string){const imported=await crypto.subtle.importKey('raw',encoder.encode(secret),{name:'HMAC',hash:'SHA-256'},false,['sign']);return hex(await crypto.subtle.sign('HMAC',imported,encoder.encode(payload)))}
function constantEqual(left:string,right:string){if(left.length!==right.length)return false;let difference=0;for(let index=0;index<left.length;index++)difference|=left.charCodeAt(index)^right.charCodeAt(index);return difference===0}

export async function signWebhookTestOnly(rawBody:string,timestamp:string,secret:string){return hmac(secret,`${timestamp}.${rawBody}`)}
export async function verifyPaymentWebhook(input:WebhookRequest):Promise<WebhookVerification>{
  if(!input.signature||!input.timestamp)return {valid:false,code:'MISSING_SIGNATURE'};
  const timestamp=Number(input.timestamp);if(!Number.isSafeInteger(timestamp))return {valid:false,code:'INVALID_TIMESTAMP'};
  if(Math.abs(input.now-timestamp)>(input.toleranceMs??300_000))return {valid:false,code:'EXPIRED_TIMESTAMP'};
  const expected=await hmac(input.secret,`${input.timestamp}.${input.rawBody}`);if(!constantEqual(expected,input.signature))return {valid:false,code:'INVALID_SIGNATURE'};
  try{const event=JSON.parse(input.rawBody) as PaymentEvent;const types=['payment.processing','payment.succeeded','payment.failed','refund.succeeded','refund.failed'];if(!event.id||!event.paymentId||!event.orderReference||!Number.isSafeInteger(event.amountMinor)||!types.includes(event.type))return {valid:false,code:'INVALID_PAYLOAD'};return {valid:true,event}}catch{return {valid:false,code:'INVALID_PAYLOAD'}}
}

export interface PaymentGateway{
  createIntent(input:{orderReference:string;money:Money;idempotencyKey:string}):Promise<PaymentIntent>;
  retrievePayment(id:string):Promise<PaymentIntent|undefined>;
  requestRefund(input:{paymentId:string;money:Money;idempotencyKey:string}):Promise<Refund>;
  retrieveRefund(id:string):Promise<Refund|undefined>;
}

export class LocalPaymentGateway implements PaymentGateway{
  private intents=new Map<string,PaymentIntent>();private intentKeys=new Map<string,string>();private refunds=new Map<string,Refund>();private refundKeys=new Map<string,string>();private events=new Set<string>();
  async createIntent(input:{orderReference:string;money:Money;idempotencyKey:string}){money(input.money);key(input.idempotencyKey);const prior=this.intentKeys.get(input.idempotencyKey);if(prior){const existing=this.intents.get(prior)!;if(existing.orderReference!==input.orderReference||existing.money.amountMinor!==input.money.amountMinor||existing.money.currency!==input.money.currency)throw new Error('IDEMPOTENCY_CONFLICT');return {...existing,money:{...existing.money}}}const id=`pay_local_${this.intents.size+1}`;const intent:PaymentIntent={id,orderReference:input.orderReference,money:{...input.money},state:'created',idempotencyKey:input.idempotencyKey,providerReference:`local:${id}`,simulated:true};this.intents.set(id,intent);this.intentKeys.set(input.idempotencyKey,id);return {...intent}}
  async retrievePayment(id:string){const found=this.intents.get(id);return found?{...found,money:{...found.money}}:undefined}
  async requestRefund(input:{paymentId:string;money:Money;idempotencyKey:string}){money(input.money);key(input.idempotencyKey);const payment=this.intents.get(input.paymentId);if(!payment||!['succeeded','partially_refunded'].includes(payment.state))throw new Error('PAYMENT_NOT_REFUNDABLE');if(input.money.currency!==payment.money.currency)throw new Error('REFUND_CURRENCY_MISMATCH');const prior=this.refundKeys.get(input.idempotencyKey);if(prior){const existing=this.refunds.get(prior)!;if(existing.paymentId!==input.paymentId||existing.money.amountMinor!==input.money.amountMinor||existing.money.currency!==input.money.currency)throw new Error('IDEMPOTENCY_CONFLICT');return {...existing,money:{...existing.money}}}const refunded=[...this.refunds.values()].filter(item=>item.paymentId===payment.id&&['requested','processing','succeeded'].includes(item.state)).reduce((sum,item)=>sum+item.money.amountMinor,0);if(input.money.amountMinor>payment.money.amountMinor-refunded)throw new Error('REFUND_EXCEEDS_REMAINING');const id=`ref_local_${this.refunds.size+1}`;const refund:Refund={id,paymentId:payment.id,money:{...input.money},state:'requested',idempotencyKey:input.idempotencyKey,providerReference:`local:${id}`,simulated:true};this.refunds.set(id,refund);this.refundKeys.set(input.idempotencyKey,id);return {...refund}}
  async retrieveRefund(id:string){const found=this.refunds.get(id);return found?{...found,money:{...found.money}}:undefined}
  applyVerifiedEvent(event:PaymentEvent){if(this.events.has(event.id))return {duplicate:true,state:this.intents.get(event.paymentId)?.state};const payment=this.intents.get(event.paymentId);if(!payment)throw new Error('UNKNOWN_PAYMENT');if(payment.orderReference!==event.orderReference)throw new Error('ORDER_REFERENCE_MISMATCH');if(payment.money.amountMinor!==event.amountMinor)throw new Error('AMOUNT_MISMATCH');if(payment.money.currency!==event.currency)throw new Error('CURRENCY_MISMATCH');const transitions:Record<PaymentEvent['type'],PaymentState[]>={'payment.processing':['created','requires_action'],'payment.succeeded':['created','requires_action','processing'],'payment.failed':['created','requires_action','processing'],'refund.succeeded':['succeeded','partially_refunded'],'refund.failed':['succeeded','partially_refunded']};if(!transitions[event.type].includes(payment.state))throw new Error('OUT_OF_ORDER_EVENT');if(event.type.startsWith('refund.')){const refund=event.refundId?this.refunds.get(event.refundId):undefined;if(!refund)throw new Error('UNKNOWN_REFUND');refund.state=event.type==='refund.succeeded'?'succeeded':'failed';if(refund.state==='succeeded'){const total=[...this.refunds.values()].filter(item=>item.paymentId===payment.id&&item.state==='succeeded').reduce((sum,item)=>sum+item.money.amountMinor,0);payment.state=total===payment.money.amountMinor?'refunded':'partially_refunded'}}else payment.state=event.type==='payment.processing'?'processing':event.type==='payment.succeeded'?'succeeded':'failed';this.events.add(event.id);return {duplicate:false,state:payment.state}}
  reconcile(){return {payments:[...this.intents.values()].map(item=>({...item})),refunds:[...this.refunds.values()].map(item=>({...item}))}}
}

