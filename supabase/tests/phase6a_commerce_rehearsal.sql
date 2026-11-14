begin;
insert into auth.users(id,email,email_confirmed_at,raw_user_meta_data) values
 ('b0000000-0000-0000-0000-000000000001','collector-a@example.test',now(),'{}'),
 ('b0000000-0000-0000-0000-000000000002','collector-b@example.test',now(),'{}'),
 ('b0000000-0000-0000-0000-000000000003','artist@example.test',now(),'{}'),
 ('b0000000-0000-0000-0000-000000000004','admin@example.test',now(),'{}'),
 ('b0000000-0000-0000-0000-000000000005','finance@example.test',now(),'{}');
insert into public.profiles(id,display_name) values
 ('b0000000-0000-0000-0000-000000000001','Collector A'),('b0000000-0000-0000-0000-000000000002','Collector B'),('b0000000-0000-0000-0000-000000000003','Artist'),('b0000000-0000-0000-0000-000000000004','Admin'),('b0000000-0000-0000-0000-000000000005','Finance') on conflict do nothing;
insert into public.user_roles(user_id,role) values('b0000000-0000-0000-0000-000000000001','collector'),('b0000000-0000-0000-0000-000000000002','collector'),('b0000000-0000-0000-0000-000000000003','artist'),('b0000000-0000-0000-0000-000000000004','admin'),('b0000000-0000-0000-0000-000000000005','finance');
insert into public.artist_profiles(id,user_id,display_name,status,public_visible) values('b1000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000003','Test Artist','approved',true);
insert into public.artworks(id,artist_id,title,status,final_price_paise,currency) values('b2000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000001','Commerce Test Work','published',100000,'INR');

set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000001',true);select set_config('request.jwt.claim.role','authenticated',true);
do $$declare saved boolean;o uuid;r uuid;begin saved:=public.tra_toggle_wishlist('b2000000-0000-0000-0000-000000000001');if not saved then raise exception 'wishlist add failed';end if;perform public.tra_record_recent_view('b2000000-0000-0000-0000-000000000001');perform public.tra_record_recent_view('b2000000-0000-0000-0000-000000000001');perform public.tra_change_shopping_bag('b2000000-0000-0000-0000-000000000001','add');o:=public.tra_create_offer('b2000000-0000-0000-0000-000000000001',90000,'INR',clock_timestamp()+interval '2 days','Synthetic test offer');r:=public.tra_create_artwork_reservation('b2000000-0000-0000-0000-000000000001',clock_timestamp()+interval '1 day','direct');if o is null or r is null then raise exception 'commerce create failed';end if;end$$;
do $$begin if (select view_count from public.recently_viewed_artworks where user_id=auth.uid())<>2 then raise exception 'recent dedupe failed';end if;end$$;

set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000002',true);
do $$begin begin perform public.tra_create_artwork_reservation('b2000000-0000-0000-0000-000000000001',clock_timestamp()+interval '1 day','direct');raise exception 'reservation conflict was accepted';exception when others then if sqlerrm not like '%ARTWORK_ALREADY_RESERVED%' then raise;end if;end;end$$;
do $$begin if exists(select 1 from public.wishlist_items) then raise exception 'cross-user wishlist leak';end if;end$$;

reset role;update public.artwork_reservations set status='released' where artwork_id='b2000000-0000-0000-0000-000000000001';
set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000004',true);
do $$declare o uuid;begin select id into o from public.offers limit 1;if public.tra_transition_offer(o,'review',1,null,'review')<>'under_review' then raise exception 'review failed';end if;if public.tra_transition_offer(o,'send_to_artist',2,null,'artist review')<>'sent_to_artist' then raise exception 'send failed';end if;if public.tra_transition_offer(o,'accept',3,null,'accepted synthetic offer')<>'accepted' then raise exception 'accept failed';end if;end$$;
do $$begin if (select count(*) from public.sales)<>1 or (select count(*) from public.offer_events)<>4 then raise exception 'offer acceptance not atomic';end if;end$$;

reset role;set local role service_role;select set_config('request.jwt.claim.role','service_role',true);
select public.tra_post_ledger_transaction('b3000000-0000-0000-0000-000000000001','test-payment-1',jsonb_build_array(jsonb_build_object('sale_id',(select id from public.sales limit 1),'entry_type','cash','account','cash','direction','debit','amount_paise',90000,'currency','INR'),jsonb_build_object('sale_id',(select id from public.sales limit 1),'entry_type','revenue','account','sales','direction','credit','amount_paise',90000,'currency','INR')));
do $$begin begin update public.financial_ledger_entries set amount_paise=1;raise exception 'ledger update succeeded';exception when others then if sqlerrm not like '%FINANCIAL_RECORD_IMMUTABLE%' then raise;end if;end;begin perform public.tra_post_ledger_transaction(gen_random_uuid(),'unbalanced',jsonb_build_array(jsonb_build_object('entry_type','cash','account','cash','direction','debit','amount_paise',1,'currency','INR')));raise exception 'unbalanced ledger succeeded';exception when others then if sqlerrm not like '%LEDGER_NOT_BALANCED%' then raise;end if;end;end$$;

reset role;insert into public.certificates(id,sale_id,artwork_id,artist_id,issuer_artist_id,reference_code,status,issue_date,verification_token_hash) select 'b4000000-0000-0000-0000-000000000001',s.id,s.artwork_id,s.artist_id,s.artist_id,'TRA-COA-TEST','complete',current_date,encode(extensions.digest('tra_coa_1234567890123456789012345678901234567890123','sha256'),'hex') from public.sales s limit 1;
set local role anon;select set_config('request.jwt.claim.role','anon',true);
do $$begin if (select count(*) from public.tra_verify_certificate('tra_coa_1234567890123456789012345678901234567890123'))<>1 then raise exception 'certificate verification failed';end if;if (select count(*) from public.tra_verify_certificate('tra_coa_invalid'))<>0 then raise exception 'invalid token disclosed data';end if;end$$;

reset role;update public.profiles set account_status='suspended' where id='b0000000-0000-0000-0000-000000000002';set local role authenticated;select set_config('request.jwt.claim.sub','b0000000-0000-0000-0000-000000000002',true);select set_config('request.jwt.claim.role','authenticated',true);
do $$begin begin perform public.tra_toggle_wishlist('b2000000-0000-0000-0000-000000000001');raise exception 'suspended mutation succeeded';exception when others then if sqlerrm not like '%ACCOUNT_INACTIVE%' then raise;end if;end;end$$;
rollback;

