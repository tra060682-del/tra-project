import 'server-only';

export type ApprovalGate='phase3-database-enforcement'|'live-auctions'|'payments'|'outbound-email'|'private-media-upload';

const environmentKeys:Record<ApprovalGate,string>={
  'phase3-database-enforcement':'TRA_PHASE3_DATABASE_ENFORCEMENT_APPROVED',
  'live-auctions':'TRA_LIVE_AUCTIONS_APPROVED',
  'payments':'TRA_PAYMENTS_APPROVED',
  'outbound-email':'TRA_OUTBOUND_EMAIL_APPROVED',
  'private-media-upload':'TRA_PRIVATE_MEDIA_UPLOAD_APPROVED',
};

export function isApprovalGateOpen(gate:ApprovalGate){return process.env[environmentKeys[gate]]==='true'}
export function requireApprovalGate(gate:ApprovalGate){if(!isApprovalGateOpen(gate))throw new Error(`APPROVAL_REQUIRED:${gate}`)}

