-- PROPOSAL ONLY. Do not apply without explicit approval. Development target only.
-- PostgreSQL enum additions must commit before later migrations use the values.
do $$begin if current_setting('app.tra_phase3_target',true) is distinct from 'ocstvctvmychromkcurw:approved-development-only' then raise exception 'TRA_PHASE3_TARGET_NOT_APPROVED';end if;end$$;
alter type public.tra_role add value if not exists 'super_admin';
alter type public.tra_role add value if not exists 'collector';
alter type public.tra_role add value if not exists 'advisor';
alter type public.tra_role add value if not exists 'finance';

