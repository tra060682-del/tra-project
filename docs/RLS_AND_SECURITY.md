# Security boundary and launch work

The migration enables RLS on every operational table and permits explicit staff/owner reads only. No browser principal has direct writes to auctions, artwork prices, roles, bid maximums, sales or audit events. Public views project approved/published records and omit private fields. Bid mutations run through a security-definer function with fixed search path, authenticated user identity, verified email, applicable terms, conflict checks and an auction row lock. Raw PostgreSQL errors are not returned from the HTTP route.

Maximums are private to the bidder. Public views expose no leader UUID or bid actor. Auction reserve values remain operational. Super-admin bootstrap uses a trusted SQL session, never email matching or public metadata. No service-role key belongs in the browser. Artist registration calls a security-definer function that requires `auth.uid()` and a verified email and inserts only the non-privileged `artist` role; it cannot accept a requested role.

Before live use: test migration in Supabase, anonymous/artist/intermediary/curator/admin isolation, role escalation, expired sessions, simultaneous bids/close, repeated request IDs and maximum leakage. Test server mutations under RLS, not just route redirects. Review view ownership and privileges in the deployed project. Add rate limits and abuse controls before exposing bid traffic. Current seed/demo UI is not connected to database queries.

Do not grant write permissions to make missing features work. Implement narrow audited services for role/association management, approval, pricing and each financial transition. Auth cookies are refreshed by `src/proxy.ts`; state-changing non-authentication APIs must continue to enforce origin/CSRF protections.
