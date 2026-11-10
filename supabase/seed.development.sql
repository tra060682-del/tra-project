-- Synthetic development-only seed. Never run against a database containing users or commerce data.
begin;

do $$
begin
  if exists(select 1 from auth.users)
     or exists(select 1 from public.buyers)
     or exists(select 1 from public.artist_profiles)
     or exists(select 1 from public.legal_acceptances)
     or exists(select 1 from public.sales) then
    raise exception 'DEVELOPMENT_SEED_REQUIRES_EMPTY_DATABASE';
  end if;
end
$$;

insert into public.legal_documents(id,code,title,audience,required_for_artist,is_active)
values(
  'de000000-0000-0000-0000-000000000001',
  'development_artist_terms',
  'Synthetic Development Artist Agreement',
  'artist',true,true
)
on conflict(code) do update set
  title=excluded.title,audience=excluded.audience,
  required_for_artist=excluded.required_for_artist,is_active=excluded.is_active;

insert into public.legal_document_versions(
  id,document_id,version,body,content_sha256,effective_at,is_published
) values(
  'de000000-0000-0000-0000-000000000002',
  'de000000-0000-0000-0000-000000000001',
  1,
  'Synthetic development artist agreement. No production legal content.',
  'c9611b11acda4069afdd967f9ec434faca7a0723a3f56cb7b070bddc6762664d',
  '2026-11-10T00:00:00Z',true
)
on conflict(document_id,version) do update set
  body=excluded.body,content_sha256=excluded.content_sha256,
  effective_at=excluded.effective_at,is_published=excluded.is_published;

insert into public.platform_settings(key,value,description)
values
  ('development_environment','{"synthetic":true,"production_data":false}',
   'Guardrail marker for tra-development'),
  ('support_details','{"email":"dev-support@example.test"}',
   'Synthetic development support contact'),
  ('default_commission','{"basis_points":3000,"synthetic":true}',
   'Synthetic commission used only in development')
on conflict(key) do update set value=excluded.value,description=excluded.description,updated_at=now();

insert into public.taxonomies(id,taxonomy_type,code,label,description,sort_order,is_active)
values
  ('de000000-0000-0000-0000-000000000010','category','development-painting','Development Painting','Synthetic category',10,true),
  ('de000000-0000-0000-0000-000000000011','medium','development-mixed-media','Development Mixed Media','Synthetic medium',10,true)
on conflict(taxonomy_type,code) do update set
  label=excluded.label,description=excluded.description,sort_order=excluded.sort_order,is_active=excluded.is_active;

commit;
