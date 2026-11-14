# Phase 5 dashboard feature matrix

Status definitions are the Phase 5 contract. “Fully Functional” means current persistence, server authorization and tests exist. Database-level claims are limited to the currently applied baseline and the disposable Phase 3.5 rehearsal.

| Dashboard | Feature | Emergent source | Next.js implementation | Database / permission | Tests | Status | Blocker / next action |
|---|---|---|---|---|---|---|---|
| Super Admin | Platform metrics | `Admin.tsx /admin/stats` | `/admin` | baseline tables; role | unit/browser | Fully Functional | Metrics without a current table show unavailable |
| Super Admin | Account directory | `PeopleAdmin.tsx` | `/admin/access` | `profiles`, `user_roles`; `roles.manage` | security | Functional with Limitations | Read-only until Phase 3 SQL is applied |
| Super Admin | Role inspection | `PeopleAdmin.tsx` | `/admin/access` | `user_roles`; `roles.manage` | security | Fully Functional | Mutation separately blocked |
| Super Admin | Role assignment/revocation | `PeopleAdmin.tsx` | disabled + server gate | Phase 3 RPCs | security | Blocked | Approve/apply Phase 3 migration and bootstrap |
| Super Admin | Suspension/reactivation | `PeopleAdmin.tsx` | disabled + server gate | Phase 3 RPCs | security | Blocked | Same as above |
| Super Admin | Invitations | `PeopleAdmin.tsx` | disabled + server gate | invitations + provider | security | Blocked | Approve schema and delivery provider |
| Super Admin | Settings inspection | `AdminOps.tsx SettingsAdmin` | `/admin/settings` | `platform_settings`; `settings.manage` | unit | Functional with Limitations | No secret values rendered |
| Super Admin | Settings mutation | `AdminOps.tsx` | typed preview controls | audited settings RPC | static | Preview Only | Approve RPC/version policy |
| Super Admin | Audit history | `AdminOps.tsx AuditAdmin` | `/admin/audit` | `audit_events`; `audit.view` | security | Fully Functional | Read-only by design |
| Super Admin | Authentication monitoring | `AdminOps.tsx` | audit categories | auth-event projection | static | Preview Only | Supabase auth event projection not approved |
| Super Admin | Integrations/media configuration | `AdminExtra.tsx` | settings cards | server-only integration store | static | Preview Only | Approve provider configuration contract |
| Super Admin | Payment activity | `AdminExtra.tsx PaymentsAdmin` | unavailable metric/finance view | payment ledger | security | Preview Only | Phase 6 ledger and provider |
| Admin | Operational metrics | `Admin.tsx` | `/admin` | RLS-scoped baseline tables | unit/browser | Fully Functional | — |
| Admin | Artist review | `Admin.tsx` | `/admin/marketplace` | `review_phase1_entity`; `artists.review` | integration | Fully Functional | Preserves legal acceptance gates |
| Admin | Artwork review | `Admin.tsx` | `/admin/marketplace` | review/availability RPCs; `artworks.review` | integration | Fully Functional | Publication still requires media/price rules |
| Admin | Representation review | `AdminOps.tsx` | `/admin/marketplace` | `review_artist_representation` | integration | Fully Functional | Requires prior artist consent |
| Admin | Enquiry inbox | `Admin.tsx` | `/admin/enquiries` | `buyer_enquiries`; `enquiries.manage` | security | Functional with Limitations | Assignment/note RPC absent |
| Admin | Collection inspection | `DiscoveryAdmin.tsx` | public collection contracts | collections tables | Phase 4 | Functional with Limitations | Dedicated ordering editor not implemented |
| Admin | Auction directory/lots | `AdminOps.tsx AuctionsAdmin` | `/admin/auctions` | auction tables; `auctions.manage` | security | Preview Only | Live-auctions gate closed |
| Admin | Bidder decisions | `AdminOps.tsx BiddersAdmin` | read-only list | bidder table | security | Preview Only | Launch approval required |
| Admin | Enquiry delivery | `Admin.tsx` | honest disabled state | email provider | static | Blocked | Provider/worker approval |
| Admin | Content pages | `Admin.tsx`, `JournalCenter.tsx` | `/admin/content` | `content_pages`; `content.manage` | security | Functional with Limitations | Read-only pending editorial RPC |
| Admin | Legal records | `LegalCenter.tsx` | `/admin/content` | legal tables | security | Functional with Limitations | Publication remains approval-gated |
| Admin | Orders/settlements | `AdminOps.tsx OrdersAdmin` | `/admin/finance` | sales/settlements; reports | security | Functional with Limitations | Read-only |
| Admin | Certificate administration | `CertCenter.tsx` | feature state | certificate-safe RPC | static | Blocked | Disclosure-safe contract not applied |
| Artist | Overview metrics | `Studio.tsx /studio` | `/artist` | owned records | unit/browser | Fully Functional | — |
| Artist | Onboarding profile | `ProfileCenter.tsx` | save/submit forms | onboarding RPCs; artist role | integration | Fully Functional | — |
| Artist | Legal acceptance | `LegalCenter.tsx` | versioned acceptance | legal RPC; artist role | integration | Fully Functional | — |
| Artist | Artwork submission | `Studio.tsx SubmitArtwork` | authoritative submission form | `submit_artist_artwork` | integration | Fully Functional | Approved artist required |
| Artist | Artwork status/history | `Studio.tsx` | owned table | artworks RLS | security | Fully Functional | — |
| Artist | Draft edit | `Studio.tsx` | limitation state | dedicated draft RPC | static | Functional with Limitations | Current safe RPC submits directly |
| Artist | Image upload | `Integrations.tsx ImageUploader` | disabled secure-upload surface | signed upload policy | security | Blocked | Approve Cloudinary/R2 server signing |
| Artist | Representation consent | `PeopleAdmin.tsx` | accept/decline | consent RPC | security | Fully Functional | — |
| Artist | Representation revocation | `PeopleAdmin.tsx` | server gate | Phase 3 revoke RPC/RLS | security | Blocked | Apply Phase 3 enforcement |
| Artist | Enquiry visibility | `Studio.tsx` | authorised count | artwork ownership RLS | security | Functional with Limitations | No messaging/delivery |
| Artist | Sales visibility | `Studio.tsx StudioSales` | authorised count | sales ownership RLS | security | Functional with Limitations | Read-only |
| Artist | Settlement visibility | `Studio.tsx` | authorised summary | settlements RLS | security | Functional with Limitations | No mutation/payment |
| Artist | Auction consideration | `Studio.tsx` | existing submission RPC | auction submissions | integration | Fully Functional | Does not enable bidding |
| Intermediary | Professional profile | `Intermediary.tsx` | `/intermediary` form | intermediary RPCs | integration | Fully Functional | — |
| Intermediary | Representation request | `Intermediary.tsx` | scope/consent form | request RPC | security | Fully Functional | Approved profile required |
| Intermediary | Consent/status history | `Intermediary.tsx` | relationship table | party RLS | security | Fully Functional | — |
| Intermediary | Expiry handling | `Intermediary.tsx` | expired relationships inactive in UI | dates | unit | Functional with Limitations | DB scope enforcement remains proposed |
| Intermediary | Artwork view | `Intermediary.tsx` | explicit preview state | Phase 3 representation RLS | security | Preview Only | Apply scoped RLS |
| Intermediary | Artwork preparation/submission | `Intermediary.tsx` | disabled | scoped transactional RPC | security | Blocked | Apply scoped RLS/RPC |
| Intermediary | Enquiries/fulfilment | `Intermediary.tsx` | disabled modules | scoped RLS | security | Blocked | Apply Phase 3 enforcement |
| Intermediary | Sales/commission | `Intermediary.tsx` | disabled modules | commission ledger | static | Blocked | Approve schema/business rules |
| Intermediary | Revocation | `PeopleAdmin.tsx` | server gate | Phase 3 revoke RPC | security | Blocked | Apply approved migration |
| Collector | Profile | `Commerce.tsx AccountSettings` | `/profile` link | self-owned `profiles` | browser | Fully Functional | — |
| Collector | Password reset | `Commerce.tsx` | Supabase recovery | Supabase Auth | browser | Fully Functional | — |
| Collector | Artwork wishlist | `Commerce.tsx` | explicit blocked state | artwork wishlist table | static | Blocked | Additive schema approval |
| Collector | Own enquiries | `Commerce.tsx` | identity-scoped table | `buyer_id=auth.uid()` | security | Functional with Limitations | Anonymous historical enquiries cannot be linked automatically |
| Collector | Orders | `Commerce.tsx` | identity-scoped sales | sales RLS | security | Functional with Limitations | Read-only; no payment |
| Collector | Auction watchlist | `Commerce.tsx` | identity-scoped list + existing API | `auction_watchlists` | API/browser | Fully Functional | Lots only |
| Collector | Auction bidding/history | `Commerce.tsx` | preview state | bidding launch gate | security | Preview Only | Live bidding prohibited |
| Collector | Offers/counteroffers | `Commerce.tsx` | blocked state | offers schema/RPC | static | Blocked | Phase 6 transactional design |
| Collector | Payments | `Commerce.tsx PayButton` | blocked state | payment provider/ledger | security | Blocked | Phase 6 approvals |
| Collector | Shipping | `Commerce.tsx` | limitation state | collector-safe projection | static | Functional with Limitations | Address-safe view required |
| Collector | Certificates | `CertCenter.tsx` | blocked state | disclosure-safe RPC/private files | security | Blocked | Apply approved certificate contract |
| Collector | Notifications/preferences | `Commerce.tsx` | unavailable metric | notifications schema | static | Blocked | Phase 6 schema/provider |

