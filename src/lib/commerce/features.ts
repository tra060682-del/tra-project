import 'server-only';import type {CommerceFeature} from './contracts';
const keys:Record<CommerceFeature,string>={'wishlist':'TRA_FEATURE_WISHLIST','recently-viewed':'TRA_FEATURE_RECENTLY_VIEWED','offers':'TRA_FEATURE_OFFERS','reservations':'TRA_FEATURE_RESERVATIONS','shopping-bag':'TRA_FEATURE_SHOPPING_BAG','checkout':'TRA_FEATURE_CHECKOUT','payments':'TRA_FEATURE_PAYMENTS','refunds':'TRA_FEATURE_REFUNDS','settlements':'TRA_FEATURE_SETTLEMENTS','certificate-verification':'TRA_FEATURE_CERTIFICATE_VERIFICATION','notifications':'TRA_FEATURE_NOTIFICATIONS','outbound-email':'TRA_FEATURE_OUTBOUND_EMAIL','private-media':'TRA_FEATURE_PRIVATE_MEDIA','courier-integrations':'TRA_FEATURE_COURIER_INTEGRATIONS','live-auctions':'TRA_FEATURE_LIVE_AUCTIONS'};
export function commerceFeatureEnabled(feature:CommerceFeature){return process.env[keys[feature]]==='true'}
export function requireCommerceFeature(feature:CommerceFeature){if(!commerceFeatureEnabled(feature))throw new Error(`FEATURE_DISABLED:${feature}`)}
export function commerceFeatureStatus(){return (Object.keys(keys) as CommerceFeature[]).map(feature=>({feature,enabled:commerceFeatureEnabled(feature),environmentKey:keys[feature]}))}

