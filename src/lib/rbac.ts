export const TRA_ROLES=['super_admin','admin','curator','artist','intermediary','collector','advisor','finance'] as const;
export type TraRole=(typeof TRA_ROLES)[number];

export const TRA_PERMISSIONS=['roles.manage','users.view','users.manage','artists.review','artworks.review','intermediaries.review','enquiries.manage','offers.manage','auctions.manage','bidders.manage','orders.manage','payments.manage','settlements.manage','requests.manage','certificates.manage','content.manage','legal.draft','legal.publish','reports.view','audit.view','settings.manage','integrations.manage'] as const;
export type TraPermission=(typeof TRA_PERMISSIONS)[number];
export type AccountStatus='active'|'suspended'|'deactivated'|'archived';

export const ROLE_PERMISSIONS:Record<TraRole,readonly TraPermission[]>={
  super_admin:[...TRA_PERMISSIONS],
  admin:['users.view','artists.review','artworks.review','intermediaries.review','enquiries.manage','offers.manage','auctions.manage','bidders.manage','orders.manage','requests.manage','certificates.manage','content.manage','legal.draft','reports.view','audit.view'],
  curator:['artists.review','artworks.review','offers.manage','certificates.manage','content.manage','legal.draft'],
  artist:[],intermediary:[],collector:[],
  advisor:['enquiries.manage','requests.manage'],
  finance:['orders.manage','payments.manage','settlements.manage','reports.view','audit.view'],
};

export function isTraRole(value:unknown):value is TraRole{return typeof value==='string'&&(TRA_ROLES as readonly string[]).includes(value)}
export function isActiveAccount(status:unknown):status is 'active'{return status==='active'}
export function permissionsForRoles(roles:readonly TraRole[]){return new Set(roles.flatMap(role=>ROLE_PERMISSIONS[role]))}
export type PermissionOverride={permission:string;effect:'grant'|'revoke';expires_at?:string|null};
export function effectivePermissions(roles:readonly TraRole[],overrides:readonly PermissionOverride[]=[],now=Date.now()){const permissions=permissionsForRoles(roles);for(const override of overrides){if(override.expires_at&&Date.parse(override.expires_at)<=now)continue;if(!(TRA_PERMISSIONS as readonly string[]).includes(override.permission))continue;if(override.effect==='revoke')permissions.delete(override.permission as TraPermission);else permissions.add(override.permission as TraPermission)}return permissions}
export function hasPermission(roles:readonly TraRole[],permission:TraPermission){return permissionsForRoles(roles).has(permission)}
export function hasAnyRole(roles:readonly TraRole[],allowed:readonly TraRole[]){return roles.some(role=>allowed.includes(role))}
export function dashboardPathForRoles(roles:readonly TraRole[]){if(hasAnyRole(roles,['super_admin','admin']))return '/admin';if(roles.includes('curator'))return '/admin/marketplace';if(roles.includes('artist'))return '/artist';if(roles.includes('intermediary'))return '/intermediary';if(roles.includes('collector'))return '/account';return '/workspace'}
export function mayBid(roles:readonly TraRole[]){return !roles.includes('finance')}
export function roleLabel(role:TraRole){return ({super_admin:'Super Admin',admin:'Admin',curator:'Curator',artist:'Artist',intermediary:'Intermediary',collector:'Collector',advisor:'Art Advisor',finance:'Finance / Operations'} as const)[role]}
