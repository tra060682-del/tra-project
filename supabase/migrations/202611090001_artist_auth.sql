-- tRA production-compatible artist registration, legal acceptance and onboarding.
-- Additive and transactional: no existing rows, policies, triggers or columns are removed.
-- Review production_schema_followup_export.sql output before approval. Do not use db push
-- until the production migration history is baselined past the fresh-only migration.

begin;

do $$
declare missing text[];
begin
  select array_agg(format('%I.%I',r.table_name,r.column_name)) into missing
  from (values
    ('profiles','id'),('profiles','display_name'),('profiles','phone'),('profiles','updated_at'),
    ('artist_profiles','id'),('artist_profiles','user_id'),('artist_profiles','display_name'),
    ('user_roles','user_id'),('user_roles','role'),
    ('artist_onboarding_requests','id'),('artist_onboarding_requests','artist_id'),
    ('artist_onboarding_requests','status'),('artist_onboarding_requests','artist_note'),
    ('artist_onboarding_requests','updated_at'),
    ('legal_documents','id'),('legal_documents','audience'),
    ('legal_documents','required_for_artist'),('legal_documents','is_active'),
    ('legal_document_versions','id'),('legal_document_versions','document_id'),
    ('legal_document_versions','body'),('legal_document_versions','content_sha256'),
    ('legal_document_versions','effective_at'),('legal_document_versions','is_published'),
    ('legal_acceptances','id'),('legal_acceptances','user_id'),
    ('legal_acceptances','version_id'),('legal_acceptances','accepted_text_snapshot'),
    ('legal_acceptances','accepted_at'),('legal_acceptances','ip_address'),
    ('legal_acceptances','user_agent')
  ) r(table_name,column_name)
  where not exists (
    select 1 from information_schema.columns c
    where c.table_schema='public' and c.table_name=r.table_name and c.column_name=r.column_name
  );
  if missing is not null then
    raise exception using message='TRA_SCHEMA_PREFLIGHT_FAILED',
      detail='Missing production columns: '||array_to_string(missing,', ');
  end if;

  if to_regprocedure('public.tra_is_admin()') is null then
    raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: public.tra_is_admin() is required by production RLS';
  end if;
  if not exists (
    select 1 from pg_attribute a join pg_class t on t.oid=a.attrelid
    join pg_namespace n on n.oid=t.relnamespace join pg_type ty on ty.oid=a.atttypid
    join pg_enum e on e.enumtypid=ty.oid
    where n.nspname='public' and t.relname='user_roles' and a.attname='role' and e.enumlabel='artist'
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: user_roles.role enum lacks artist'; end if;
  if not exists (
    select 1 from pg_enum e join pg_type ty on ty.oid=e.enumtypid
    join pg_namespace n on n.oid=ty.typnamespace
    where n.nspname='public' and ty.typname='artist_status' and e.enumlabel='submitted'
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: artist_status enum lacks submitted'; end if;

  if exists(select 1 from public.user_roles group by user_id,role having count(*)>1) then
    raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: duplicate user_roles rows require review';
  end if;
  if exists(select 1 from public.artist_onboarding_requests group by artist_id having count(*)>1) then
    raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: duplicate onboarding rows require review';
  end if;
  if exists(select 1 from public.legal_acceptances group by user_id,version_id having count(*)>1) then
    raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: duplicate legal acceptances require review';
  end if;

  if not exists (
    select 1 from pg_index i where i.indrelid='public.profiles'::regclass and i.indisunique
      and i.indpred is null and i.indnkeyatts=1 and i.indkey[0]=(
        select attnum from pg_attribute where attrelid='public.profiles'::regclass and attname='id'
      )
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: profiles.id must be unique for safe upsert'; end if;
  if not exists (
    select 1 from pg_index i where i.indrelid='public.artist_profiles'::regclass and i.indisunique
      and i.indpred is null and i.indnkeyatts=1 and i.indkey[0]=(
        select attnum from pg_attribute where attrelid='public.artist_profiles'::regclass and attname='user_id'
      )
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: artist_profiles.user_id must be unique for safe upsert'; end if;

  if not exists (
    select 1 from pg_constraint c where c.contype='f'
      and c.conrelid='public.profiles'::regclass and c.confrelid='auth.users'::regclass
      and c.conkey=array[(select attnum from pg_attribute where attrelid=c.conrelid and attname='id')]::smallint[]
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: profiles.id foreign key to auth.users.id is required'; end if;
  if not exists (
    select 1 from pg_constraint c where c.contype='f'
      and c.conrelid='public.user_roles'::regclass and c.confrelid='auth.users'::regclass
      and c.conkey=array[(select attnum from pg_attribute where attrelid=c.conrelid and attname='user_id')]::smallint[]
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: user_roles.user_id foreign key to auth.users.id is required'; end if;
  if not exists (
    select 1 from pg_constraint c where c.contype='f'
      and c.conrelid='public.artist_profiles'::regclass and c.confrelid='auth.users'::regclass
      and c.conkey=array[(select attnum from pg_attribute where attrelid=c.conrelid and attname='user_id')]::smallint[]
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: artist_profiles.user_id foreign key to auth.users.id is required'; end if;
  if not exists (
    select 1 from pg_constraint c where c.contype='f'
      and c.conrelid='public.artist_onboarding_requests'::regclass
      and c.confrelid='public.artist_profiles'::regclass
      and c.conkey=array[(select attnum from pg_attribute where attrelid=c.conrelid and attname='artist_id')]::smallint[]
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: onboarding.artist_id foreign key to artist_profiles.id is required'; end if;
  if not exists (
    select 1 from pg_constraint c where c.contype='f'
      and c.conrelid='public.legal_document_versions'::regclass and c.confrelid='public.legal_documents'::regclass
      and c.conkey=array[(select attnum from pg_attribute where attrelid=c.conrelid and attname='document_id')]::smallint[]
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: legal version document foreign key is required'; end if;
  if not exists (
    select 1 from pg_constraint c where c.contype='f'
      and c.conrelid='public.legal_acceptances'::regclass and c.confrelid='auth.users'::regclass
      and c.conkey=array[(select attnum from pg_attribute where attrelid=c.conrelid and attname='user_id')]::smallint[]
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: legal acceptance user foreign key is required'; end if;
  if not exists (
    select 1 from pg_constraint c where c.contype='f'
      and c.conrelid='public.legal_acceptances'::regclass and c.confrelid='public.legal_document_versions'::regclass
      and c.conkey=array[(select attnum from pg_attribute where attrelid=c.conrelid and attname='version_id')]::smallint[]
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: legal acceptance version foreign key is required'; end if;

  if to_regprocedure('public.register_current_user_as_artist(text)') is null then
    raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: existing register_current_user_as_artist(text) is required';
  end if;
  if to_regprocedure('public.tra_owns_artist(uuid)') is null then
    raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: public.tra_owns_artist(uuid) is required';
  end if;
  if exists(
    select 1 from (values
      ('profiles'),('user_roles'),('artist_onboarding_requests'),
      ('artist_profiles'),('legal_documents'),('legal_document_versions'),('legal_acceptances')
    ) required(table_name)
    where not exists(
      select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='public' and c.relname=required.table_name and c.relrowsecurity
    )
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: required production RLS is not enabled'; end if;
  if exists(
    select 1 from (values
      ('profiles','profile_admin_insert'),('profiles','profile_read'),('profiles','profile_update'),
      ('user_roles','admin_all'),('user_roles','role_self_read'),
      ('artist_profiles','artist_admin_all'),('artist_profiles','artist_public_read'),
      ('artist_profiles','artist_self_insert'),('artist_profiles','artist_self_update'),
      ('artist_onboarding_requests','onboarding_admin'),('artist_onboarding_requests','onboarding_read'),
      ('legal_documents','admin_all'),('legal_documents','legal_artist_read'),('legal_documents','legal_public_read'),
      ('legal_document_versions','admin_all'),('legal_document_versions','legal_versions_artist'),('legal_document_versions','legal_versions_read'),
      ('legal_acceptances','legal_acceptance_admin'),('legal_acceptances','legal_acceptance_insert'),('legal_acceptances','legal_acceptance_read')
    ) required(table_name,policy_name)
    where not exists(
      select 1 from pg_policies p where p.schemaname='public'
        and p.tablename=required.table_name and p.policyname=required.policy_name
    )
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: required production RLS policy is missing'; end if;
  if to_regprocedure('public.accept_artist_legal_version(uuid,text,inet,text)') is not null
     or to_regprocedure('public.save_artist_onboarding(jsonb)') is not null
     or to_regprocedure('public.submit_artist_onboarding()') is not null
     or to_regprocedure('public.tra_prepare_legal_acceptance()') is not null then
    raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: a target RPC/trigger function already exists';
  end if;
  if exists(select 1 from pg_trigger where tgname='tra_legal_acceptance_immutable_snapshot' and not tgisinternal) then
    raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: target trigger name already exists';
  end if;
  if to_regclass('public.tra_user_roles_user_role_uq') is not null
     or to_regclass('public.tra_artist_onboarding_artist_uq') is not null
     or to_regclass('public.tra_legal_acceptance_user_version_uq') is not null then
    raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: a target index name already exists';
  end if;
  if exists(
    select 1 from information_schema.columns where table_schema='public'
      and table_name='legal_acceptances'
      and column_name in ('acceptance_statement','accepted_content_sha256')
      and data_type<>'text'
  ) then raise exception 'TRA_SCHEMA_PREFLIGHT_FAILED: acceptance evidence columns must be text'; end if;
end
$$;

-- Evidence columns complement the existing immutable body snapshot.
alter table public.legal_acceptances add column if not exists acceptance_statement text;
alter table public.legal_acceptances add column if not exists accepted_content_sha256 text;

-- Add invariants only when production does not already have an equivalent unique index.
do $$
begin
  if not exists (
    select 1 from pg_index i join pg_class t on t.oid=i.indrelid
    join pg_namespace n on n.oid=t.relnamespace
    where n.nspname='public' and t.relname='user_roles' and i.indisunique and i.indpred is null
      and (select array_agg(a.attname::text order by u.ord)
           from unnest(i.indkey::smallint[]) with ordinality u(attnum,ord)
           join pg_attribute a on a.attrelid=t.oid and a.attnum=u.attnum)=array['user_id','role']
  ) then execute 'create unique index tra_user_roles_user_role_uq on public.user_roles(user_id,role)'; end if;
  if not exists (
    select 1 from pg_index i join pg_class t on t.oid=i.indrelid
    join pg_namespace n on n.oid=t.relnamespace
    where n.nspname='public' and t.relname='artist_onboarding_requests' and i.indisunique and i.indpred is null
      and (select array_agg(a.attname::text order by u.ord)
           from unnest(i.indkey::smallint[]) with ordinality u(attnum,ord)
           join pg_attribute a on a.attrelid=t.oid and a.attnum=u.attnum)=array['artist_id']
  ) then execute 'create unique index tra_artist_onboarding_artist_uq on public.artist_onboarding_requests(artist_id)'; end if;
  if not exists (
    select 1 from pg_index i join pg_class t on t.oid=i.indrelid
    join pg_namespace n on n.oid=t.relnamespace
    where n.nspname='public' and t.relname='legal_acceptances' and i.indisunique and i.indpred is null
      and (select array_agg(a.attname::text order by u.ord)
           from unnest(i.indkey::smallint[]) with ordinality u(attnum,ord)
           join pg_attribute a on a.attrelid=t.oid and a.attnum=u.attnum)=array['user_id','version_id']
  ) then execute 'create unique index tra_legal_acceptance_user_version_uq on public.legal_acceptances(user_id,version_id)'; end if;
end
$$;

create function public.tra_prepare_legal_acceptance()
returns trigger language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare v_body text; v_hash text;
begin
  if tg_op<>'INSERT' then raise exception 'LEGAL_ACCEPTANCE_IMMUTABLE'; end if;
  if auth.uid() is not null and not public.tra_is_admin() then
    if not exists(select 1 from public.user_roles where user_id=auth.uid() and role::text='artist') then
      raise exception 'ARTIST_ROLE_REQUIRED';
    end if;
    new.user_id:=auth.uid();
  end if;
  select v.body,v.content_sha256 into v_body,v_hash
  from public.legal_document_versions v join public.legal_documents d on d.id=v.document_id
  where v.id=new.version_id and v.is_published and v.effective_at<=now()
    and d.is_active and d.audience in ('artist','all');
  if not found then raise exception 'LEGAL_VERSION_NOT_ACCEPTABLE'; end if;
  new.accepted_text_snapshot:=v_body;
  new.accepted_content_sha256:=v_hash;
  new.acceptance_statement:=coalesce(nullif(btrim(new.acceptance_statement),''),'I accept this legal document version.');
  new.accepted_at:=clock_timestamp();
  new.user_agent:=left(new.user_agent,1000);
  return new;
end
$$;

create trigger tra_legal_acceptance_immutable_snapshot
before insert or update or delete on public.legal_acceptances
for each row execute function public.tra_prepare_legal_acceptance();

create or replace function public.register_current_user_as_artist(p_display_name text default null)
returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare
  current_user_id uuid:=auth.uid();
  confirmed_at timestamptz;
  metadata_name text;
  artist_profile_id uuid;
begin
  if current_user_id is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  select email_confirmed_at,nullif(btrim(raw_user_meta_data->>'display_name'),'')
    into confirmed_at,metadata_name from auth.users where id=current_user_id;
  if confirmed_at is null then raise exception 'VERIFIED_EMAIL_REQUIRED'; end if;
  metadata_name:=coalesce(nullif(btrim(p_display_name),''),metadata_name);
  if metadata_name is null or char_length(metadata_name) not between 2 and 120 then raise exception 'VALID_DISPLAY_NAME_REQUIRED'; end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text,0));
  insert into public.user_roles(user_id,role) values(current_user_id,'artist') on conflict(user_id,role) do nothing;
  insert into public.artist_profiles(user_id,display_name)
    values(current_user_id,metadata_name)
    on conflict(user_id) do update set display_name=public.artist_profiles.display_name
    returning id into artist_profile_id;
  insert into public.artist_onboarding_requests(artist_id)
    values(artist_profile_id) on conflict(artist_id) do nothing;
  return artist_profile_id;
end
$$;

create function public.accept_artist_legal_version(p_version_id uuid,p_acceptance_statement text,p_ip_address inet default null,p_user_agent text default null)
returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare current_user_id uuid:=auth.uid(); acceptance_id uuid;
begin
  if current_user_id is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  if not exists(select 1 from public.user_roles where user_id=current_user_id and role::text='artist') then raise exception 'ARTIST_ROLE_REQUIRED'; end if;
  if nullif(btrim(p_acceptance_statement),'') is null then raise exception 'ACCEPTANCE_STATEMENT_REQUIRED'; end if;
  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text||':'||p_version_id::text,0));
  insert into public.legal_acceptances(user_id,version_id,accepted_text_snapshot,acceptance_statement,ip_address,user_agent)
    select current_user_id,v.id,v.body,btrim(p_acceptance_statement),p_ip_address,left(p_user_agent,1000)
    from public.legal_document_versions v join public.legal_documents d on d.id=v.document_id
    where v.id=p_version_id and v.is_published and v.effective_at<=now()
      and d.is_active and d.audience in ('artist','all')
    on conflict(user_id,version_id) do nothing
    returning id into acceptance_id;
  if acceptance_id is null then select id into acceptance_id from public.legal_acceptances where user_id=current_user_id and version_id=p_version_id; end if;
  if acceptance_id is null then raise exception 'LEGAL_VERSION_NOT_ACCEPTABLE'; end if;
  return acceptance_id;
end
$$;

create function public.save_artist_onboarding(p_profile_data jsonb)
returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare request_id uuid; artist_profile_id uuid; unknown_key text;
begin
  if auth.uid() is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  if not exists(select 1 from public.user_roles where user_id=auth.uid() and role::text='artist') then raise exception 'ARTIST_ROLE_REQUIRED'; end if;
  select id into artist_profile_id from public.artist_profiles where user_id=auth.uid();
  if artist_profile_id is null then raise exception 'ARTIST_PROFILE_REQUIRED'; end if;
  if p_profile_data is null or jsonb_typeof(p_profile_data)<>'object' then raise exception 'PROFILE_DATA_MUST_BE_OBJECT'; end if;
  select fields.key into unknown_key from jsonb_object_keys(p_profile_data) as fields(key)
    where fields.key not in ('display_name','phone','artist_note') limit 1;
  if unknown_key is not null then raise exception 'UNSUPPORTED_PROFILE_FIELD: %',unknown_key; end if;
  if p_profile_data ? 'display_name' and char_length(btrim(p_profile_data->>'display_name')) not between 2 and 120 then raise exception 'VALID_DISPLAY_NAME_REQUIRED'; end if;
  if p_profile_data ? 'phone' and char_length(coalesce(p_profile_data->>'phone',''))>50 then raise exception 'PHONE_TOO_LONG'; end if;
  if p_profile_data ? 'artist_note' and char_length(coalesce(p_profile_data->>'artist_note',''))>4000 then raise exception 'ARTIST_NOTE_TOO_LONG'; end if;
  update public.profiles set
    display_name=case when p_profile_data ? 'display_name' then nullif(btrim(p_profile_data->>'display_name'),'') else display_name end,
    phone=case when p_profile_data ? 'phone' then nullif(btrim(p_profile_data->>'phone'),'') else phone end,
    updated_at=now() where id=auth.uid();
  update public.artist_onboarding_requests set
    artist_note=case when p_profile_data ? 'artist_note' then nullif(btrim(p_profile_data->>'artist_note'),'') else artist_note end,
    updated_at=now()
    where artist_id=artist_profile_id and status::text in ('draft','changes_requested') returning id into request_id;
  if request_id is null then raise exception 'ONBOARDING_NOT_EDITABLE'; end if;
  return request_id;
end
$$;

create function public.submit_artist_onboarding()
returns uuid language plpgsql security definer set search_path=public,auth,pg_temp as $$
declare request_id uuid; artist_profile_id uuid;
begin
  if auth.uid() is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  if not exists(select 1 from public.user_roles where user_id=auth.uid() and role::text='artist') then raise exception 'ARTIST_ROLE_REQUIRED'; end if;
  select id into artist_profile_id from public.artist_profiles where user_id=auth.uid();
  if artist_profile_id is null then raise exception 'ARTIST_PROFILE_REQUIRED'; end if;
  if exists(
    select 1 from public.legal_documents d
    where d.is_active and d.required_for_artist and d.audience in ('artist','all')
      and not exists(
        select 1 from public.legal_acceptances a where a.user_id=auth.uid() and a.version_id=(
          select v.id from public.legal_document_versions v
          where v.document_id=d.id and v.is_published and v.effective_at<=now()
          order by v.effective_at desc,v.version desc limit 1
        )
      )
  ) then raise exception 'MANDATORY_LEGAL_ACCEPTANCE_REQUIRED'; end if;
  update public.artist_onboarding_requests set status='submitted',submitted_at=now(),updated_at=now()
    where artist_id=artist_profile_id and status::text in ('draft','changes_requested') returning id into request_id;
  if request_id is null then raise exception 'ONBOARDING_NOT_SUBMITTABLE'; end if;
  return request_id;
end
$$;

revoke all on function public.tra_prepare_legal_acceptance() from public,anon,authenticated;
revoke all on function public.register_current_user_as_artist(text) from public,anon;
revoke all on function public.accept_artist_legal_version(uuid,text,inet,text) from public,anon;
revoke all on function public.save_artist_onboarding(jsonb) from public,anon;
revoke all on function public.submit_artist_onboarding() from public,anon;
grant execute on function public.register_current_user_as_artist(text) to authenticated;
grant execute on function public.accept_artist_legal_version(uuid,text,inet,text) to authenticated;
grant execute on function public.save_artist_onboarding(jsonb) to authenticated;
grant execute on function public.submit_artist_onboarding() to authenticated;

commit;
