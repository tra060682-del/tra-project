# Phase 5 Intermediary dashboard

`/intermediary` implements profile save/submission, approved-artist selection, scoped representation requests, relationship history, consent/approval states, dates and expiry-aware presentation. It is based on Emergent `Intermediary.tsx` while preserving Supabase Auth and the Phase 3 consent model.

The current safe sequence is intermediary request → explicit artist response → administrative review. Scope flags are recorded, but Phase 5 does not treat them as database-enforced delegated artwork access because the Phase 3 representation RLS is unapplied. Consequently represented artwork preparation, enquiry/fulfilment visibility, sale visibility and commissions are disabled. No artist credentials are shared or impersonated.

Expired relationships are inactive in the application. Revocation actions fail closed at the server approval gate; immediate database-wide revocation requires the approved Phase 3 functions and policies.

