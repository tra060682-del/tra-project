import 'server-only';
import {redirect} from 'next/navigation';
import {supabase} from './supabase/server';
import {dashboardPathForRoles,effectivePermissions,hasAnyRole,isActiveAccount,isTraRole,type AccountStatus,type PermissionOverride,type TraPermission,type TraRole} from './rbac';

export class AuthorizationError extends Error{
  constructor(public code:'AUTHENTICATION_REQUIRED'|'ACCOUNT_INACTIVE'|'PERMISSION_DENIED',public status:401|403){super(code);this.name='AuthorizationError'}
}

export async function getOptionalAuthContext(){
  if(!process.env.NEXT_PUBLIC_SUPABASE_URL||!process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)return null;
  const db=await supabase();
  const {data:{user}}=await db.auth.getUser();
  if(!user)return null;
  const [{data:roleRows,error:roleError},{data:profile,error:profileError},overrideResult]=await Promise.all([db.from('user_roles').select('role').eq('user_id',user.id),db.from('profiles').select('*').eq('id',user.id).maybeSingle(),db.from('user_permission_overrides').select('permission,effect,expires_at').eq('user_id',user.id)]);
  if(roleError)throw new AuthorizationError('PERMISSION_DENIED',403);
  const roles=(roleRows??[]).map(row=>row.role).filter(isTraRole);
  const accountStatus=((profile as {account_status?:AccountStatus}|null)?.account_status??'active') as AccountStatus;
  if(profileError)throw new AuthorizationError('PERMISSION_DENIED',403);
  const proposalMissing=overrideResult.error&&['PGRST205','42P01'].includes(overrideResult.error.code??'');
  if(overrideResult.error&&!proposalMissing)throw new AuthorizationError('PERMISSION_DENIED',403);
  const permissions=effectivePermissions(roles,(overrideResult.data??[]) as PermissionOverride[]);
  return {db,user,roles,permissions,accountStatus,landingPath:dashboardPathForRoles(roles)};
}

export async function requireAuthContext(){const context=await getOptionalAuthContext();if(!context)throw new AuthorizationError('AUTHENTICATION_REQUIRED',401);if(!isActiveAccount(context.accountStatus))throw new AuthorizationError('ACCOUNT_INACTIVE',403);return context}
export async function requireAuthenticated(){try{return await requireAuthContext()}catch(error){if(error instanceof AuthorizationError)redirect(error.status===401?'/login':'/access-denied');throw error}}
export async function requireRole(allowed:readonly TraRole[]){try{const context=await requireAuthContext();if(!hasAnyRole(context.roles,allowed))throw new AuthorizationError('PERMISSION_DENIED',403);return context}catch(error){if(error instanceof AuthorizationError)redirect(error.status===401?'/login':'/access-denied');throw error}}
export async function requirePermission(permission:TraPermission){try{const context=await requireAuthContext();if(!context.permissions.has(permission))throw new AuthorizationError('PERMISSION_DENIED',403);return context}catch(error){if(error instanceof AuthorizationError)redirect(error.status===401?'/login':'/access-denied');throw error}}
export async function requireApiPermission(permission?:TraPermission){const context=await requireAuthContext();if(permission&&!context.permissions.has(permission))throw new AuthorizationError('PERMISSION_DENIED',403);return context}
export function authorizationResponse(error:unknown){if(error instanceof AuthorizationError)return Response.json({error:error.code},{status:error.status});throw error}
