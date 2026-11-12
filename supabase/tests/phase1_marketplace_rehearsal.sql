\set ON_ERROR_STOP on
create or replace function pg_temp.assert_true(ok boolean,message text) returns void language plpgsql as $$begin if not coalesce(ok,false) then raise exception 'ASSERTION_FAILED: %',message;end if;end$$;

insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at) values
('00000000-0000-0000-0000-000000000000','b0000000-0000-0000-0000-000000000001','authenticated','authenticated','phase1.admin@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','b0000000-0000-0000-0000-000000000002','authenticated','authenticated','phase1.curator@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','b0000000-0000-0000-0000-000000000003','authenticated','authenticated','phase1.artist@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','b0000000-0000-0000-0000-000000000004','authenticated','authenticated','phase1.intermediary@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','b0000000-0000-0000-0000-000000000005','authenticated','authenticated','phase1.outsider@example.test',crypt('Synthetic-Only-1',gen_salt('bf')),now(),'{}','{}',now(),now());
insert into public.user_roles(user_id,role) values('b0000000-0000-0000-0000-000000000001','admin'),('b0000000-0000-0000-0000-000000000002','curator');

begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000003',true);select public.register_current_user_as_artist('Synthetic Artist');commit;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000004',true);select public.register_current_user_as_intermediary('Synthetic Representative','Synthetic Agency');select public.save_intermediary_profile('{"email":"representative@example.test","biography":"Synthetic rehearsal profile only"}'::jsonb);select public.submit_intermediary_profile();commit;
select pg_temp.assert_true((select count(*)=1 and bool_and(role::text='intermediary') from public.user_roles where user_id='b0000000-0000-0000-0000-000000000004'),'intermediary registration assigned an unexpected role');

begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000005',true);do $$begin insert into public.user_roles(user_id,role) values(auth.uid(),'admin');raise exception 'ASSERTION_FAILED: self-assigned admin';exception when insufficient_privilege then null;end$$;rollback;

update public.artist_profiles set status='approved',public_visible=true where user_id='b0000000-0000-0000-0000-000000000003';
begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000001',true);select public.review_phase1_entity('intermediary',(select id from public.intermediary_profiles where user_id='b0000000-0000-0000-0000-000000000004'),'approved','Synthetic approval',null);commit;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000004',true);select public.request_artist_representation((select id from public.artist_profiles where user_id='b0000000-0000-0000-0000-000000000003'),'{"can_submit_artwork":true}'::jsonb,'Synthetic request');commit;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000003',true);select public.respond_to_representation((select id from public.artist_representations limit 1),true);commit;

begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000002',true);do $$begin perform public.review_artist_representation((select id from public.artist_representations limit 1),true,'Forbidden curator approval');raise exception 'ASSERTION_FAILED: curator approved representation';exception when others then if sqlerrm not like '%FORBIDDEN%' then raise;end if;end$$;rollback;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000001',true);select public.review_artist_representation((select id from public.artist_representations limit 1),true,'Synthetic admin approval');commit;

begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000005',true);select pg_temp.assert_true((select count(*)=0 from public.artist_representations),'unrelated user read representation');rollback;

begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000003',true);select public.submit_artist_artwork('{"title":"Synthetic Phase 1 Work","description":"Disposable rehearsal artwork","artist_expected_paise":"5000000","declaration":"I declare this is my synthetic original rehearsal artwork."}'::jsonb);commit;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000002',true);select public.review_phase1_entity('artwork',(select id from public.artworks where title='Synthetic Phase 1 Work'),'under_review','Curatorial review',null);do $$begin perform public.review_phase1_entity('artwork',(select id from public.artworks where title='Synthetic Phase 1 Work'),'approved','Forbidden final approval',5000000);raise exception 'ASSERTION_FAILED: curator approved artwork';exception when others then if sqlerrm not like '%DECISION_NOT_ALLOWED%' then raise;end if;end$$;commit;
begin;set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000001',true);select public.review_phase1_entity('artwork',(select id from public.artworks where title='Synthetic Phase 1 Work'),'approved','Administrative approval',5000000);do $$begin perform public.review_phase1_entity('artwork',(select id from public.artworks where title='Synthetic Phase 1 Work'),'published','Missing approved media',5000000);raise exception 'ASSERTION_FAILED: artwork published without approved media';exception when others then if sqlerrm not like '%PUBLICATION_REQUIREMENTS_NOT_MET%' then raise;end if;end$$;commit;

select pg_temp.assert_true(not has_table_privilege('anon','public.intermediary_profiles','SELECT'),'anonymous can read intermediary profiles');
select pg_temp.assert_true(not has_table_privilege('anon','public.artist_representations','SELECT'),'anonymous can read representations');
select 'phase1_marketplace_security' test_suite,'PASS' result;
