export type JobType='notification.dispatch'|'email.deliver'|'offer.expire'|'reservation.expire'|'payment.reconcile'|'refund.reconcile'|'certificate.generate'|'media.process'|'shipping.refresh';
export type JobStatus='queued'|'running'|'retrying'|'succeeded'|'dead_letter';
export type Job={id:string;type:JobType;payload:Record<string,unknown>;idempotencyKey:string;status:JobStatus;attempt:number;maxAttempts:number;runAt:number;lastError?:string};
export type JobHandler=(job:Readonly<Job>)=>Promise<void>;
export class RetryableJobError extends Error{readonly retryAfterMs?:number;constructor(message:string,retryAfterMs?:number){super(message);this.retryAfterMs=retryAfterMs}}
export class LocalJobRunner{
  private jobs=new Map<string,Job>();private keys=new Map<string,string>();private handlers=new Map<JobType,JobHandler>();readonly deadLetters:Job[]=[];
  register(type:JobType,handler:JobHandler){this.handlers.set(type,handler)}
  enqueue(input:{type:JobType;payload:Record<string,unknown>;idempotencyKey:string;runAt:number;maxAttempts?:number}){const prior=this.keys.get(input.idempotencyKey);if(prior)return {...this.jobs.get(prior)!};const id=`job_local_${this.jobs.size+1}`,job:Job={id,type:input.type,payload:structuredClone(input.payload),idempotencyKey:input.idempotencyKey,status:'queued',attempt:0,maxAttempts:input.maxAttempts??3,runAt:input.runAt};this.jobs.set(id,job);this.keys.set(input.idempotencyKey,id);return {...job}}
  async runDue(now:number){const due=[...this.jobs.values()].filter(job=>['queued','retrying'].includes(job.status)&&job.runAt<=now).sort((a,b)=>a.runAt-b.runAt||a.id.localeCompare(b.id));const results=[];for(const job of due){const handler=this.handlers.get(job.type);job.status='running';job.attempt++;try{if(!handler)throw new Error('JOB_HANDLER_MISSING');await handler(Object.freeze({...job,payload:structuredClone(job.payload)}));job.status='succeeded';results.push({id:job.id,status:job.status})}catch(error){job.lastError=error instanceof Error?error.message:'JOB_FAILED';if(error instanceof RetryableJobError&&job.attempt<job.maxAttempts){job.status='retrying';job.runAt=now+(error.retryAfterMs??Math.min(60_000,1000*2**(job.attempt-1)))}else{job.status='dead_letter';this.deadLetters.push({...job,payload:structuredClone(job.payload)})}results.push({id:job.id,status:job.status})}}return results}
  get(id:string){const job=this.jobs.get(id);return job?{...job,payload:structuredClone(job.payload)}:undefined}
}

export type ScheduledTask={name:'offers.expire'|'reservations.expire'|'notifications.retry'|'reconciliation.check'|'certificates.maintain'|'audit.retention'|'health.check';intervalMs:number;jobType:JobType};
export class DeterministicScheduler{
  private claims=new Set<string>();
  due(task:ScheduledTask,lastScheduledAt:number,now:number){const executions:number[]=[];for(let at=lastScheduledAt+task.intervalMs;at<=now;at+=task.intervalMs){const key=`${task.name}:${at}`;if(!this.claims.has(key)){this.claims.add(key);executions.push(at)}}return executions}
}

