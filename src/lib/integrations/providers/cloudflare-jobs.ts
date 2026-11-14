import {IntegrationError} from '../core.ts';
import type {Job,JobHandler,JobType,ScheduledTask} from '../jobs.ts';

export interface QueueLike{send(message:unknown,options?:{contentType?:'json';delaySeconds?:number}):Promise<void>}
export interface QueueMessageLike<T=unknown>{id:string;body:T;attempts:number;ack():void;retry(options?:{delaySeconds?:number}):void}
export interface QueueBatchLike<T=unknown>{messages:QueueMessageLike<T>[];queue:string}
export type QueueEnvelope={version:1;job:Job;correlationId:string;enqueuedAt:number};

export class CloudflareQueueProducer{
  private keys=new Set<string>();
  private queue:QueueLike;
  constructor(queue:QueueLike,config:{enabled:boolean;approvalReference?:string}){this.queue=queue;if(!config.enabled||config.approvalReference!=='phase6b2-sandbox-approved')throw new IntegrationError('CLOUDFLARE_QUEUES_DISABLED')}
  async enqueue(input:{type:JobType;payload:Record<string,unknown>;idempotencyKey:string;runAt:number;maxAttempts?:number;correlationId:string;now:number}){if(this.keys.has(input.idempotencyKey))return {duplicate:true};const job:Job={id:crypto.randomUUID(),type:input.type,payload:structuredClone(input.payload),idempotencyKey:input.idempotencyKey,status:'queued',attempt:0,maxAttempts:input.maxAttempts??3,runAt:input.runAt};await this.queue.send({version:1,job,correlationId:input.correlationId,enqueuedAt:input.now} satisfies QueueEnvelope,{contentType:'json',delaySeconds:Math.max(0,Math.ceil((input.runAt-input.now)/1000))});this.keys.add(input.idempotencyKey);return {duplicate:false,job}}
}

export class CloudflareQueueConsumer{
  private completed=new Set<string>();private handlers:Map<JobType,JobHandler>;private maxBackoffSeconds:number;
  constructor(handlers:Map<JobType,JobHandler>,maxBackoffSeconds=300){this.handlers=handlers;this.maxBackoffSeconds=maxBackoffSeconds}
  async consume(batch:QueueBatchLike<QueueEnvelope>){for(const message of batch.messages){const envelope=message.body;if(envelope?.version!==1||!envelope.job?.idempotencyKey){message.ack();continue}if(this.completed.has(envelope.job.idempotencyKey)){message.ack();continue}const handler=this.handlers.get(envelope.job.type);if(!handler){message.retry({delaySeconds:this.maxBackoffSeconds});continue}try{await handler(Object.freeze({...envelope.job,attempt:message.attempts,payload:structuredClone(envelope.job.payload)}));this.completed.add(envelope.job.idempotencyKey);message.ack()}catch{if(message.attempts>=envelope.job.maxAttempts)message.ack();else message.retry({delaySeconds:Math.min(this.maxBackoffSeconds,2**Math.max(0,message.attempts-1))})}}}
}

export function scheduledJobs(input:{tasks:ScheduledTask[];scheduledTime:number;lastRuns:Record<string,number>}){return input.tasks.flatMap(task=>{const last=input.lastRuns[task.name]??input.scheduledTime-task.intervalMs;if(last+task.intervalMs>input.scheduledTime)return [];return [{type:task.jobType,idempotencyKey:`schedule:${task.name}:${input.scheduledTime}`,runAt:input.scheduledTime,payload:{task:task.name,scheduledTime:input.scheduledTime}}]})}
