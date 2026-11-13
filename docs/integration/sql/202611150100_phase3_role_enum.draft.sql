-- PROPOSAL ONLY. Do not apply without explicit approval. Development target only.
-- PostgreSQL enum additions must commit before later migrations use the values.
alter type public.staff_role add value if not exists 'collector';
alter type public.staff_role add value if not exists 'advisor';
alter type public.staff_role add value if not exists 'finance';

