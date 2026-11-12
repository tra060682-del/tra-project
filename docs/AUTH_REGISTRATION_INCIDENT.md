# Development artist-registration incident

## Root cause

The deployed development Worker reached the intended development Supabase project, but Supabase Auth rejected public signup with HTTP 429 and the code `over_email_send_rate_limit`. The application converted every provider error into one generic message, hiding the actionable cause.

A separate callback configuration defect was also found: the development Supabase Auth site URL was `http://localhost:3000`, with no development Worker redirect URL allowed. This did not cause the initial signup rejection, but it would have sent a successful verification flow to localhost.

## Corrections

- Registration now maps known Supabase Auth error codes to safe, useful messages and logs only the error code and status—not email addresses, passwords, tokens, or raw database details.
- The development Supabase Auth site URL is `https://tra-development.tra060682.workers.dev`.
- The allowed development redirect URL includes `https://tra-development.tra060682.workers.dev/auth/callback`.
- The development Auth/RLS smoke test now asserts that Supabase preserves the exact artist callback URL in a generated verification link.

No database migration, RLS weakening, production configuration change, or production data change was required.

## Remaining platform action

Configure a development-only custom SMTP provider and review the development Auth email rate limits before relying on repeated public signup tests. Until then, the built-in email provider may reject additional messages when its quota is exhausted. Keep production SMTP credentials and production Supabase settings separate.
