import {createClient} from '@supabase/supabase-js';

const {DEV_SUPABASE_URL, DEV_SUPABASE_PUBLISHABLE_KEY, DEV_SUPABASE_SERVICE_ROLE_KEY, DEV_SUPABASE_PROJECT_REF, PROD_SUPABASE_PROJECT_REF} = process.env;
for (const [name, value] of Object.entries({DEV_SUPABASE_URL, DEV_SUPABASE_PUBLISHABLE_KEY, DEV_SUPABASE_SERVICE_ROLE_KEY, DEV_SUPABASE_PROJECT_REF})) {
  if (!value) throw new Error(`${name} is required`);
}
const url = new URL(DEV_SUPABASE_URL);
if (url.hostname !== `${DEV_SUPABASE_PROJECT_REF}.supabase.co`) throw new Error('Development URL does not match DEV_SUPABASE_PROJECT_REF');
if (PROD_SUPABASE_PROJECT_REF && DEV_SUPABASE_PROJECT_REF === PROD_SUPABASE_PROJECT_REF) throw new Error('Development and production project refs must not equal');

const admin = createClient(DEV_SUPABASE_URL, DEV_SUPABASE_SERVICE_ROLE_KEY, {auth: {persistSession: false}});
const runId = `${Date.now()}-${crypto.randomUUID().slice(0, 8)}`;
const email = `ci.artist.${runId}@example.test`;
const password = `Synthetic-${crypto.randomUUID()}-A1!`;
const userIds = [];
const clientFor = () => createClient(DEV_SUPABASE_URL, DEV_SUPABASE_PUBLISHABLE_KEY, {auth: {persistSession: false}});
const removeSyntheticUser = async userId => {
  const [artists,intermediaries] = await Promise.all([
    admin.from('artist_profiles').select('id').eq('user_id',userId),
    admin.from('intermediary_profiles').select('id').eq('user_id',userId),
  ]);
  if (artists.error) throw artists.error;
  if (intermediaries.error) throw intermediaries.error;
  const reviewerCleanup = await Promise.all([
    admin.from('artist_representations').update({reviewed_by:null,reviewed_at:null}).eq('reviewed_by',userId),
    admin.from('intermediary_profiles').update({reviewed_by:null,reviewed_at:null}).eq('reviewed_by',userId),
    admin.from('artworks').update({reviewed_by:null}).eq('reviewed_by',userId),
  ]);
  for (const result of reviewerCleanup) if (result.error) throw result.error;
  if (artists.data.length) { const result=await admin.from('artist_representations').delete().in('artist_id',artists.data.map(row=>row.id)); if(result.error)throw result.error; }
  if (intermediaries.data.length) { const result=await admin.from('artist_representations').delete().in('intermediary_id',intermediaries.data.map(row=>row.id)); if(result.error)throw result.error; }
  const intermediaryCleanup=await admin.from('intermediary_profiles').delete().eq('user_id',userId);
  if(intermediaryCleanup.error)throw intermediaryCleanup.error;
  for(const table of ['status_history','audit_events']){const result=await admin.from(table).delete().eq('actor_id',userId);if(result.error)throw result.error;}
  const prepared = await admin.rpc('tra_cleanup_development_synthetic_user',{p_user_id:userId});
  if (prepared.error) throw prepared.error;
  const removed = await admin.auth.admin.deleteUser(userId);
  if (removed.error) throw removed.error;
};
const createConfirmed = async (prefix, role) => {
  const created = await admin.auth.admin.createUser({
    email: `ci.${prefix}.${runId}@example.test`, password, email_confirm: true,
    user_metadata: {display_name: `CI ${prefix}`},
  });
  if (created.error) throw created.error;
  userIds.push(created.data.user.id);
  if (role) {
    const assigned = await admin.from('user_roles').insert({user_id: created.data.user.id, role});
    if (assigned.error) throw assigned.error;
  }
  const client = clientFor();
  const signedIn = await client.auth.signInWithPassword({email: created.data.user.email, password});
  if (signedIn.error) throw signedIn.error;
  return {client, user: created.data.user};
};
try {
  // Generate a real signup confirmation token without sending email to an external inbox.
  const link = await admin.auth.admin.generateLink({type: 'signup', email, password, options: {data: {display_name: 'CI Artist'}}});
  if (link.error) throw link.error;
  userIds.push(link.data.user.id);
  const client = clientFor();
  const rejected = await client.auth.signInWithPassword({email, password});
  if (!rejected.error) throw new Error('Unverified artist obtained a session');
  const tokenHash = link.data.properties?.hashed_token;
  if (!tokenHash) throw new Error('Signup confirmation token was not generated');
  const verified = await client.auth.verifyOtp({type: 'signup', token_hash: tokenHash});
  if (verified.error || !verified.data.session) throw verified.error || new Error('Email verification did not create a session');

  const first = await client.rpc('register_current_user_as_artist', {p_display_name: 'CI Artist'});
  if (first.error) throw first.error;
  const second = await client.rpc('register_current_user_as_artist', {p_display_name: 'CI Artist'});
  if (second.error || first.data !== second.data) throw second.error || new Error('Registration is not idempotent');
  const roles = await client.from('user_roles').select('role');
  if (roles.error || roles.data.length !== 1 || roles.data[0].role !== 'artist') throw roles.error || new Error('Unexpected role assignment');
  const onboarding = await client.from('artist_onboarding_requests').select('status');
  if (onboarding.error || onboarding.data.length !== 1 || onboarding.data[0].status !== 'draft') throw onboarding.error || new Error('Draft onboarding missing');

  const saved = await client.rpc('save_artist_onboarding', {p_profile_data: {display_name:'CI Artist', artist_note:'Synthetic CI draft'}});
  if (saved.error) throw saved.error;
  const earlySubmit = await client.rpc('submit_artist_onboarding');
  if (!earlySubmit.error || !earlySubmit.error.message.includes('MANDATORY_LEGAL_ACCEPTANCE_REQUIRED')) throw new Error('Submission was not gated by legal acceptance');
  const accepted = await client.rpc('accept_artist_legal_version', {
    p_version_id:'de000000-0000-0000-0000-000000000002',
    p_acceptance_statement:'I accept the synthetic development agreement',
    p_ip_address:null,
    p_user_agent:'tra-development-ci',
  });
  if (accepted.error) throw accepted.error;
  const submitted = await client.rpc('submit_artist_onboarding');
  if (submitted.error) throw submitted.error;

  const secondArtist = await createConfirmed('second-artist');
  const secondRegistration = await secondArtist.client.rpc('register_current_user_as_artist', {p_display_name:'CI Second Artist'});
  if (secondRegistration.error) throw secondRegistration.error;
  const isolated = await secondArtist.client.from('artist_onboarding_requests').select('id,artist_id');
  if (isolated.error || isolated.data.length !== 1 || isolated.data[0].id === submitted.data) throw isolated.error || new Error('Artist ownership isolation failed');
  const escalation = await secondArtist.client.from('user_roles').insert({user_id:secondArtist.user.id, role:'admin'});
  if (!escalation.error) throw new Error('Artist assigned itself admin');
  const selfApproval = await client.from('artist_onboarding_requests').update({status:'approved'}).eq('id',submitted.data).select();
  if (!selfApproval.error && selfApproval.data.length) throw new Error('Artist approved its own onboarding');

  const administrator = await createConfirmed('administrator', 'admin');
  const approved = await administrator.client.from('artist_onboarding_requests')
    .update({status:'approved',reviewed_by:administrator.user.id,reviewed_at:new Date().toISOString()})
    .eq('id',submitted.data).select('status,reviewed_by').single();
  if (approved.error || approved.data.status !== 'approved') throw approved.error || new Error('Admin approval failed');
  const artistProfile = await administrator.client.from('artist_profiles').select('id').eq('user_id',link.data.user.id).single();
  if (artistProfile.error) throw artistProfile.error;
  const artistApproved = await administrator.client.rpc('review_phase1_entity',{p_entity_type:'artist',p_entity:artistProfile.data.id,p_decision:'approved',p_remarks:'Synthetic development approval',p_final_price_paise:null});
  if (artistApproved.error) throw artistApproved.error;

  const intermediary = await createConfirmed('intermediary');
  const intermediaryRegistered = await intermediary.client.rpc('register_current_user_as_intermediary',{p_display_name:'CI Intermediary',p_organisation:'Synthetic Agency'});
  if (intermediaryRegistered.error) throw intermediaryRegistered.error;
  const intermediaryRoles = await intermediary.client.from('user_roles').select('role');
  if (intermediaryRoles.error || intermediaryRoles.data.length !== 1 || intermediaryRoles.data[0].role !== 'intermediary') throw intermediaryRoles.error || new Error('Unexpected intermediary role assignment');
  const intermediarySaved = await intermediary.client.rpc('save_intermediary_profile',{p_data:{email:'ci.intermediary@example.test',biography:'Synthetic CI intermediary profile'}});
  if (intermediarySaved.error) throw intermediarySaved.error;
  const intermediarySubmitted = await intermediary.client.rpc('submit_intermediary_profile');
  if (intermediarySubmitted.error) throw intermediarySubmitted.error;
  const intermediaryApproved = await administrator.client.rpc('review_phase1_entity',{p_entity_type:'intermediary',p_entity:intermediarySubmitted.data,p_decision:'approved',p_remarks:'Synthetic development approval',p_final_price_paise:null});
  if (intermediaryApproved.error) throw intermediaryApproved.error;
  const representation = await intermediary.client.rpc('request_artist_representation',{p_artist:artistProfile.data.id,p_scopes:{can_submit_artwork:true},p_note:'Synthetic consent request'});
  if (representation.error) throw representation.error;
  const artistResponse = await client.rpc('respond_to_representation',{p_representation:representation.data,p_accept:true});
  if (artistResponse.error || artistResponse.data !== 'pending_admin') throw artistResponse.error || new Error('Artist representation consent failed');
  const unrelatedRepresentations = await secondArtist.client.from('artist_representations').select('id');
  if (unrelatedRepresentations.error || unrelatedRepresentations.data.length) throw unrelatedRepresentations.error || new Error('Representation ownership isolation failed');
  const representationApproved = await administrator.client.rpc('review_artist_representation',{p_representation:representation.data,p_approve:true,p_remarks:'Synthetic development approval'});
  if (representationApproved.error || representationApproved.data !== 'approved') throw representationApproved.error || new Error('Representation admin approval failed');
  const tamper = await administrator.client.from('legal_acceptances')
    .update({acceptance_statement:'tampered'}).eq('id',accepted.data);
  if (!tamper.error) throw new Error('Legal acceptance evidence was mutable');

  const anonymous = clientFor();
  const anonymousRows = await anonymous.from('artist_onboarding_requests').select('id');
  if (anonymousRows.error || anonymousRows.data.length) throw anonymousRows.error || new Error('Anonymous onboarding access was allowed');
  const loggedOut = await client.auth.signOut();
  if (loggedOut.error || (await client.auth.getSession()).data.session) throw loggedOut.error || new Error('Logout failed');
  const loggedIn = await client.auth.signInWithPassword({email,password});
  if (loggedIn.error || !loggedIn.data.session) throw loggedIn.error || new Error('Verified login failed');

  console.log('Development auth/RLS smoke PASS: signup verification, login/logout, artist/intermediary provisioning, legal gate/evidence, representation consent, ownership isolation, admin approval, anonymous restriction, and escalation prevention.');
} finally {
  let cleanupFailed = false;
  for (const userId of userIds.reverse()) {
    try { await removeSyntheticUser(userId); }
    catch { cleanupFailed = true; console.error('Synthetic user cleanup failed; remove it manually by the reported CI run timestamp.'); }
  }
  if (cleanupFailed) process.exitCode = 1;
}
