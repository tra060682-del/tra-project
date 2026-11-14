export type NotificationChannel='in_app'|'email';
export type NotificationPriority='normal'|'security'|'operational';
export type NotificationEvent={id:string;recipientId:string;category:string;title:string;body:string;dedupeKey:string;priority:NotificationPriority;channels:NotificationChannel[]};
export type NotificationPreference={category:string;inApp:boolean;email:boolean};
export function resolveChannels(event:NotificationEvent,preference:NotificationPreference|undefined){if(event.priority==='security')return event.channels;return event.channels.filter(channel=>channel==='in_app'?(preference?.inApp??true):(preference?.email??false))}
export class LocalNotificationDispatcher{private delivered=new Set<string>();readonly deliveries:{eventId:string;channel:NotificationChannel;simulated:true}[]=[];dispatch(event:NotificationEvent,preference?:NotificationPreference){const results=[];for(const channel of resolveChannels(event,preference)){const key=`${event.dedupeKey}:${channel}`;if(this.delivered.has(key))continue;this.delivered.add(key);const result={eventId:event.id,channel,simulated:true} as const;this.deliveries.push(result);results.push(result)}return results}}

