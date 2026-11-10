-- READ ONLY hosted development state verification.
select
  (select count(*) from auth.users where email like 'ci.%@example.test') as synthetic_auth_users,
  (select count(*) from public.artist_profiles) as artist_profiles,
  (select count(*) from public.legal_acceptances) as legal_acceptances,
  (select count(*) from public.legal_documents where code='development_artist_terms') as synthetic_legal_documents,
  (select count(*) from public.platform_settings where key='development_environment'
     and value @> '{"synthetic":true,"production_data":false}'::jsonb) as development_markers,
  has_function_privilege('anon','public.tra_cleanup_development_synthetic_user(uuid)','execute') as anon_cleanup_execute,
  has_function_privilege('authenticated','public.tra_cleanup_development_synthetic_user(uuid)','execute') as authenticated_cleanup_execute,
  has_function_privilege('service_role','public.tra_cleanup_development_synthetic_user(uuid)','execute') as service_cleanup_execute;
