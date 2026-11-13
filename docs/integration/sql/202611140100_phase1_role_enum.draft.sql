-- DESIGN DRAFT ONLY. DO NOT ADD TO supabase/migrations OR APPLY WITHOUT APPROVAL.
-- Kept separate because newly added PostgreSQL enum values must commit before later use.
do $$ begin
  if current_setting('app.tra_phase1_target', true) <> 'ocstvctvmychromkcurw:approved-development-only' then
    raise exception 'PHASE1_DRAFT_REFUSED';
  end if;
end $$;

alter type public.tra_role add value if not exists 'super_admin';
alter type public.tra_role add value if not exists 'finance';
alter type public.tra_role add value if not exists 'advisor';
