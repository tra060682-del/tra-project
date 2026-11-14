export type NotificationCategory='artist_onboarding'|'artwork_submission'|'artwork_approval'|'artwork_rejection'|'buyer_enquiry'|'offer_received'|'counteroffer'|'order_update'|'shipping_update'|'certificate_issued'|'account_security';
const categories=new Set<NotificationCategory>(['artist_onboarding','artwork_submission','artwork_approval','artwork_rejection','buyer_enquiry','offer_received','counteroffer','order_update','shipping_update','certificate_issued','account_security']);
export type NotificationPreference={category:NotificationCategory;inApp:boolean;email:boolean};
export function normalizePreferences(input:NotificationPreference[]){const byCategory=new Map<NotificationCategory,NotificationPreference>();for(const item of input){if(!categories.has(item.category))throw new Error('INVALID_NOTIFICATION_CATEGORY');byCategory.set(item.category,{category:item.category,inApp:Boolean(item.inApp),email:Boolean(item.email)})}return [...byCategory.values()]}

