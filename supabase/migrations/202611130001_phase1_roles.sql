-- Add non-administrative marketplace roles in a separate commit boundary.
-- PostgreSQL requires newly added enum values to be committed before dependent objects use them.
begin;
alter type public.tra_role add value if not exists 'intermediary';
alter type public.tra_role add value if not exists 'curator';
alter type public.tra_role add value if not exists 'collector';
commit;
