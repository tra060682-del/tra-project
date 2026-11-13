# Database field crosswalk

Status: implementation-ready mapping design derived from a read-only dump of development project `ocstvctvmychromkcurw` on 2026-11-14. No staging import or database write was performed.

## Coverage

| Source collection | Verified records | Mapping disposition |
|---|---:|---|
| `analytics_events` | 25 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `articles` | 44 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `artists` | 13 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `artworks` | 27 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `auctions` | 9 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `audit_logs` | 106 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `bidders` | 1 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `certificates` | 1 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `email_log` | 51 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `legal_acceptances` | 1 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `legal_docs` | 15 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `legal_versions` | 15 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `platform_settings` | 4 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `taxonomy_terms` | 85 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |
| `users` | 3 | Mapped below; rows marked hold remain in staging until prerequisites resolve. |

**Total: 400 records across 15 collections.** `emergent_staging` remains private and unchanged. Source string identifiers are resolved through `emergent_staging.id_map`; they are never cast directly to UUID.

## Identifier and relationship rules

- Allocate each target UUID once in `emergent_staging.id_map`; enforce one source pair and one target pair. Re-runs reuse the same mapping.
- Supabase Auth identities are never created by SQL transformation. User/bidder/acceptance rows remain on hold until verified invite or magic-link account linking.
- Artist, artwork, taxonomy, legal and content relationships resolve only after their parent map exists; unresolved references abort the transaction.
- Monetary source values are integer rupees and become integer paise by checked multiplication by 100.
- The nine approved pseudonymisations and five attribution-review flags remain unchanged; the placeholder is never accepted as a verified reviewer.
- Embedded `tscheck_*` and `v2test_*` legal-version keys in platform settings are explicitly discarded as QA residue.

## analytics_events

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| at | string | analytics_events | occurred_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | extend |
| day | string | analytics_events | occurred_on | date | copy | none | type, length and nullability checks | derive |
| label | string | analytics_events | label | text | copy | none | type, length and nullability checks | extend |
| ref | string | analytics_events | reference | text | copy | none | type, length and nullability checks | extend |
| type | string | analytics_events | event_name | text | copy | none | type, length and nullability checks | extend |
| visitor | string | analytics_events | visitor_hash | text | copy | none | type, length and nullability checks | extend |

## articles

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| author | string | content_pages | author_name | text | copy | none | type, length and nullability checks | extend |
| body | string | content_pages | body | text | copy | none | type, length and nullability checks | extend |
| category | string | content_pages | category | text | copy | none | type, length and nullability checks | extend |
| cover | string | content_pages | cover_url | text | copy | none | HTTPS; asset-manifest match; rights/approval gate | extend |
| created_at | string | content_pages | created_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | extend |
| editorial_note | string | content_pages | editorial_note | text | copy | none | type, length and nullability checks | extend |
| excerpt | string | content_pages | excerpt | text | copy | none | type, length and nullability checks | extend |
| featured | boolean | content_pages | featured | boolean | copy | none | type, length and nullability checks | extend |
| id | string | content_pages | source_record_id | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | extend |
| image_credit | string | content_pages | image_credit | text | copy | none | type, length and nullability checks | extend |
| published_at | string | content_pages | published_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | extend |
| reading_minutes | number | content_pages | reading_minutes | integer | copy | none | type, length and nullability checks | extend |
| related_artist_ids | array | content_relations | related_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| related_artwork_ids | array | content_relations | related_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| review_history | array | audit_events | metadata | jsonb | copy | none | type, length and nullability checks | ready |
| review_history[] | object | audit_events | metadata | jsonb | copy | none | type, length and nullability checks | ready |
| review_history[].action | string | audit_events | metadata | jsonb | copy | none | type, length and nullability checks | ready |
| review_history[].at | string | audit_events | metadata | jsonb | copy | none | type, length and nullability checks | ready |
| review_history[].by | string | audit_events | metadata | jsonb | copy | none | type, length and nullability checks | ready |
| review_history[].note | string | audit_events | metadata | jsonb | copy | none | type, length and nullability checks | ready |
| seo_description | string | content_pages | seo_description | text | copy | none | type, length and nullability checks | extend |
| seo_title | string | content_pages | seo_title | text | copy | none | type, length and nullability checks | extend |
| slug | string | content_pages | slug | text | copy | none | type, length and nullability checks | extend |
| sources | array | content_pages | source_citations | jsonb | copy | none | type, length and nullability checks | extend |
| sources[] | string | content_pages | source_citations | jsonb | copy | none | type, length and nullability checks | extend |
| status | string | content_pages | publication_status | text | explicit status map; reject unknown | none | type, length and nullability checks | extend |
| tags | array | content_pages | tags | text[] | copy | none | type, length and nullability checks | extend |
| tags[] | string | content_pages | tags | text[] | copy | none | type, length and nullability checks | extend |
| title | string | content_pages | title | text | copy | none | type, length and nullability checks | extend |
| updated_at | string | content_pages | updated_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | extend |
| views | number | content_pages | view_count | bigint | copy | none | type, length and nullability checks | extend |
| voice_type | string | content_pages | metadata.voice_type | jsonb | copy | none | type, length and nullability checks | extend |

## artists

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| artist_code | string | artist_profiles | reference_code | text | copy | none | type, length and nullability checks | ready |
| bio | string | artist_profiles | biography | text | copy | none | type, length and nullability checks | ready |
| created_at | string | artist_profiles | created_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | ready |
| email | string | artist_profiles | email | text | copy | none | normalize for comparison; do not grant identity/role from email alone | ready |
| id | string | artist_profiles | source_record_id | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | extend |
| is_demo | boolean | artist_profiles | metadata.is_demo | jsonb | copy | none | type, length and nullability checks | ready |
| location | string | artist_profiles | city/state | text | copy | none | type, length and nullability checks | ready |
| name | string | artist_profiles | display_name | text | copy | none | type, length and nullability checks | ready |
| participation | string | artist_profiles | participation | text | copy | none | type, length and nullability checks | extend |
| phone | string | artist_profiles | phone | text | copy | none | type, length and nullability checks | ready |
| portrait | string | artist_profiles | profile_image_url | text | copy | none | HTTPS; asset-manifest match; rights/approval gate | extend |
| public_reference | string | artist_profiles | public_reference | text | copy | none | type, length and nullability checks | extend |
| review_note | string | artist_profiles | admin_remarks | text | copy | none | type, length and nullability checks | ready |
| since | number | artist_profiles | practice_since_year | integer | copy | none | type, length and nullability checks | extend |
| status | string | artist_profiles | status | artist_status | explicit status map; reject unknown | none | type, length and nullability checks | ready |
| styles | array | artist_profile_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| styles[] | string | artist_profile_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| user_id | null | artist_profiles | user_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | ready |

## artworks

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| artforms | array | artwork_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| artforms[] | string | artwork_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| artist_id | string | artworks | artist_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | ready |
| artist_name | string | artworks | (verification only) | text | copy | none | type, length and nullability checks | derive |
| availability | string | artworks | status | artwork_status | explicit status map; reject unknown | none | type, length and nullability checks | ready |
| category | string | artwork_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| collections | array | collection_artworks | collection_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | ready |
| colours | array | artwork_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| created_at | string | artworks | created_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | ready |
| description | string | artworks | description | text | copy | none | type, length and nullability checks | ready |
| featured | boolean | artworks | featured | boolean | copy | none | type, length and nullability checks | extend |
| height_cm | number | artworks | height_cm | numeric(10,2) | copy | none | type, length and nullability checks | ready |
| id | string | artworks | source_record_id | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | extend |
| images | array | artwork_media | secure_url | text | copy | none | HTTPS; asset-manifest match; rights/approval gate | ready |
| images[] | string | artwork_media | secure_url | text | copy | none | type, length and nullability checks | ready |
| is_demo | boolean | artworks | metadata.is_demo | jsonb | copy | none | type, length and nullability checks | ready |
| medium | string | artworks | medium taxonomy | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | ready |
| price | number | artworks | final_price_paise | bigint | integer rupees × 100 => paise | none | non-negative bigint; exact source sum reconciliation | ready |
| review_note | string | artworks | admin_remarks | text | copy | none | type, length and nullability checks | ready |
| status | string | artworks | status | artwork_status | explicit status map; reject unknown | none | type, length and nullability checks | ready |
| style | string | artwork_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| styles | array | artwork_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| styles[] | string | artwork_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| subjects | array | artwork_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| subjects[] | string | artwork_taxonomies | taxonomy_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | normalize |
| taxonomy_at | string | artwork_classification_reviews | reviewed_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | normalize |
| taxonomy_by | string | artwork_classification_reviews | reviewer_reference | text | copy | none | type, length and nullability checks | normalize |
| taxonomy_source | string | artwork_classification_reviews | source | text | copy | none | type, length and nullability checks | normalize |
| taxonomy_verified | boolean | artwork_classification_reviews | verified | boolean | copy | none | type, length and nullability checks | normalize |
| title | string | artworks | title | text | copy | none | type, length and nullability checks | extend |
| views | number | artworks | view_count | bigint | copy | none | type, length and nullability checks | extend |
| width_cm | number | artworks | width_cm | numeric(10,2) | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | ready |
| year | number | artworks | year_created | integer | copy | none | type, length and nullability checks | ready |

## auctions

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| artist_id | string | artworks | artist_id verification | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| artist_name | string | artist_profiles | display_name verification | text | copy | none | type, length and nullability checks | hold |
| artwork_id | string | auction_lots | artwork_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| bids | array | auction_bid_events | displayed_paise/actor/created_at | normalized | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| bids[] | object | auction_bid_events | displayed_paise/actor/created_at | normalized | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| bids[].amount | number | auction_bid_events | displayed_paise/actor/created_at | normalized | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| bids[].at | string | auction_bid_events | displayed_paise/actor/created_at | normalized | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| bids[].bidder | string | auction_bid_events | displayed_paise/actor/created_at | normalized | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| buyer_premium_pct | number | auction_lots | buyer_premium_rate_snapshot | numeric | copy | none | type, length and nullability checks | hold |
| closed | boolean | auction_lots | status | auction_lot_status | copy | none | type, length and nullability checks | hold |
| closed_at | string | auction_lots | closed_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | hold |
| current_bid | number | auction_lots | current_paise | bigint | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | hold |
| day_offset | number | auctions | (legacy scheduling input) | integer | copy | none | type, length and nullability checks | hold |
| ends_at | string | auctions | ends_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | hold |
| estimate_high | number | auction_lots | estimate_high_paise | bigint | integer rupees × 100 => paise | none | non-negative bigint; exact source sum reconciliation | hold |
| estimate_low | number | auction_lots | estimate_low_paise | bigint | integer rupees × 100 => paise | none | non-negative bigint; exact source sum reconciliation | hold |
| extended_count | number | auction_lots | extension_count | integer | copy | none | type, length and nullability checks | hold |
| has_reserve | boolean | auction_lots | reserve_paise derived | boolean | copy | none | type, length and nullability checks | derive |
| hour | number | auctions | (legacy scheduling input) | integer | copy | none | type, length and nullability checks | hold |
| id | string | auction_lots | source_record_id | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | hold |
| image | string | artwork_media | secure_url verification | text | copy | none | HTTPS; asset-manifest match; rights/approval gate | hold |
| increment | number | auction_lots | increment_paise | bigint | integer rupees × 100 => paise | none | non-negative bigint; exact source sum reconciliation | hold |
| is_demo | boolean | auction_lots | metadata.is_demo | jsonb | copy | none | type, length and nullability checks | hold |
| leader_user_id | null | auction_lots | current_leader | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| lot | string | auction_lots | lot_number | integer | copy | none | type, length and nullability checks | hold |
| paused | boolean | auctions | paused | boolean | copy | none | type, length and nullability checks | hold |
| proxies | object | auction_proxy_bids | maximum_paise | normalized | copy | FK only after referenced source id resolves | type, length and nullability checks | hold |
| reserve_price | null | auction_lots | reserve_paise | bigint | integer rupees × 100 => paise | none | non-negative bigint; exact source sum reconciliation | hold |
| result | object | sales/audit_events | normalized result | normalized | copy | FK only after referenced source id resolves | type, length and nullability checks | hold |
| result.hammer | number | sales/audit_events | normalized result | normalized | copy | FK only after referenced source id resolves | type, length and nullability checks | hold |
| result.order_id | string | sales/audit_events | normalized result | normalized | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| result.outcome | string | sales/audit_events | normalized result | normalized | copy | FK only after referenced source id resolves | type, length and nullability checks | hold |
| result.reserve_met | boolean | sales/audit_events | normalized result | normalized | copy | FK only after referenced source id resolves | type, length and nullability checks | hold |
| result.winner_alias | string | sales/audit_events | normalized result | normalized | copy | FK only after referenced source id resolves | type, length and nullability checks | hold |
| starting_bid | number | auction_lots | opening_paise | bigint | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | hold |
| starts_at | string | auctions | starts_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | hold |
| style | string | artwork_taxonomies | taxonomy_id verification | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | hold |
| title | string | artworks | title verification | text | copy | none | type, length and nullability checks | hold |
| version | number | auction_lots | state_version | bigint | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | hold |

## audit_logs

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| action | string | audit_events | action | text | copy | none | type, length and nullability checks | ready |
| actor_email | string | audit_events | metadata.actor_email | jsonb | copy | none | normalize for comparison; do not grant identity/role from email alone | ready |
| actor_id | string | audit_events | actor_reference | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | ready |
| at | string | audit_events | created_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | ready |
| detail | string | audit_events | metadata.detail | jsonb | copy | none | type, length and nullability checks | ready |
| entity | string | audit_events | entity_type | text | copy | none | type, length and nullability checks | ready |
| entity_id | string | audit_events | entity_reference | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | ready |
| id | string | audit_events | source_record_id | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | extend |

## bidders

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| alias | string | bidder_profiles | alias | text | copy | none | type, length and nullability checks | hold |
| city | string | bidder_profiles | city | text | copy | none | type, length and nullability checks | hold |
| created_at | string | bidder_profiles | created_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | hold |
| email | string | bidder_profiles | email_snapshot | text | copy | none | normalize for comparison; do not grant identity/role from email alone | hold |
| full_name | string | bidder_profiles | full_name | text | copy | none | type, length and nullability checks | hold |
| phone | string | bidder_profiles | phone | text | copy | none | type, length and nullability checks | hold |
| status | string | bidder_eligibility | status | bidder_status | explicit status map; reject unknown | none | type, length and nullability checks | hold |
| terms_version | string | auction_acceptances | terms_version_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | hold |
| user_id | string | bidder_profiles | user_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |

## certificates

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| artist_name | string | certificates | snapshot.artist_name | jsonb | copy | none | type, length and nullability checks | hold |
| artwork_id | string | certificates | artwork_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| declaration_type | string | certificates | snapshot.declaration_type | jsonb | copy | none | type, length and nullability checks | hold |
| dimensions | string | certificates | snapshot.dimensions | jsonb | copy | none | type, length and nullability checks | hold |
| id | string | certificates | source_record_id | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | hold |
| image | string | certificate_files | storage_path | text | copy | none | HTTPS; asset-manifest match; rights/approval gate | hold |
| issued_at | string | certificates | signed_at | date | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | hold |
| medium | string | certificates | snapshot.medium | jsonb | copy | none | type, length and nullability checks | hold |
| number | string | certificates | reference_code | text | copy | none | type, length and nullability checks | hold |
| order_id | string | certificates | sale_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| owner_name | string | certificates | snapshot.owner_name | jsonb | copy | none | type, length and nullability checks | hold |
| provenance | string | certificates | snapshot.provenance | jsonb | copy | none | type, length and nullability checks | hold |
| status | string | certificates | status | certificate_status | explicit status map; reject unknown | none | type, length and nullability checks | hold |
| title | string | certificates | snapshot.title | jsonb | copy | none | type, length and nullability checks | hold |
| year | number | certificates | snapshot.year | jsonb | copy | none | type, length and nullability checks | hold |

## email_log

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| attempts | number | notification_deliveries | attempt_count | integer | copy | none | type, length and nullability checks | extend |
| body | string | notification_deliveries | body | text | copy | none | type, length and nullability checks | extend |
| category | string | notification_deliveries | category | text | copy | none | type, length and nullability checks | extend |
| claimed_at | string | notification_deliveries | claimed_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | extend |
| created_at | string | notification_deliveries | created_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | extend |
| error | null/string | notification_deliveries | last_error | text | copy | none | type, length and nullability checks | extend |
| id | string | notification_deliveries | source_record_id | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | extend |
| link | string | notification_deliveries | action_url | text | copy | none | type, length and nullability checks | extend |
| provider_id | string | notification_deliveries | provider_reference | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | extend |
| sent_at | string | notification_deliveries | sent_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | extend |
| status | string | notification_deliveries | status | text | explicit status map; reject unknown | none | type, length and nullability checks | extend |
| subject | string | notification_deliveries | subject | text | copy | none | type, length and nullability checks | extend |
| to | string | notification_deliveries | recipient | text | copy | none | type, length and nullability checks | extend |
| user_id | null | notification_deliveries | user_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | extend |

## legal_acceptances

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| at | string | legal_acceptances | accepted_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | hold |
| doc | string | legal_document_versions | document_id lookup | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| id | string | legal_acceptances | source_record_id | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | hold |
| user_id | string | legal_acceptances | user_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| version | string | legal_acceptances | version_id lookup | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |

## legal_docs

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| archived | boolean | legal_documents | is_active inverse | boolean | copy | none | type, length and nullability checks | ready |
| current_version | number | legal_documents | metadata.current_version | jsonb | copy | none | type, length and nullability checks | ready |
| key | string | legal_documents | code | text | copy | none | type, length and nullability checks | ready |
| published_version | null | legal_documents | metadata.published_version | jsonb | copy | none | type, length and nullability checks | ready |
| roles | array | legal_documents | audiences | text[] | copy | none | type, length and nullability checks | extend |
| roles[] | string | legal_documents | audiences | text[] | copy | none | type, length and nullability checks | extend |
| status | string | legal_documents | is_active | boolean | explicit status map; reject unknown | none | type, length and nullability checks | ready |
| title | string | legal_documents | title | text | copy | none | type, length and nullability checks | extend |
| updated_at | string | legal_documents | updated_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | ready |

## legal_versions

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| body | string | legal_document_versions | body | text | copy | none | type, length and nullability checks | ready |
| change_summary | string | legal_document_versions | change_summary | text | copy | none | type, length and nullability checks | extend |
| created_at | string | legal_document_versions | created_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | ready |
| created_by | string | legal_document_versions | created_by_reference | text | copy | none | type, length and nullability checks | extend |
| doc_key | string | legal_document_versions | document_id lookup | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | ready |
| material | boolean | legal_document_versions | material_change | boolean | copy | none | type, length and nullability checks | extend |
| status | string | legal_document_versions | is_published | boolean | explicit status map; reject unknown | none | type, length and nullability checks | ready |
| title | string | legal_document_versions | title | text | copy | none | type, length and nullability checks | extend |
| version | number | legal_document_versions | version | integer | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | ready |

## platform_settings

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| anti_snipe_extend_min | number | platform_settings | value.anti_snipe_extend_min | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| anti_snipe_window_min | number | platform_settings | value.anti_snipe_window_min | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| bank_transfer_instructions | string | platform_settings | value.bank_transfer_instructions | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| brand_name | string | platform_settings | value.brand_name | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| buyer_premium_pct | number | platform_settings | value.buyer_premium_pct | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| commission_deposit_pct | number | platform_settings | value.commission_deposit_pct | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| commission_revision_limit | number | platform_settings | value.commission_revision_limit | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| contact_email | string | platform_settings | value.contact_email | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| contact_phone | string | platform_settings | value.contact_phone | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| currency | string | platform_settings | value.currency | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| default_bid_increment | number | platform_settings | value.default_bid_increment | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| default_message | string | platform_settings | value.default_message | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| domestic_shipping_fee | number | platform_settings | value.domestic_shipping_fee | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| enabled | boolean | platform_settings | value.enabled | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| flags | object | platform_settings | value.flags | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| flags.auto_approve_bidders | boolean | platform_settings | value.flags.auto_approve_bidders | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| flags.bidding_enabled | boolean | platform_settings | value.flags.bidding_enabled | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| flags.buy_now_enabled | boolean | platform_settings | value.flags.buy_now_enabled | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| flags.newsletter_enabled | boolean | platform_settings | value.flags.newsletter_enabled | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| flags.offers_enabled | boolean | platform_settings | value.flags.offers_enabled | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| flags.real_money_enabled | boolean | platform_settings | value.flags.real_money_enabled | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| gst_pct | number | platform_settings | value.gst_pct | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| intermediary_commission_pct | number | platform_settings | value.intermediary_commission_pct | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| legal_versions | object | platform_settings | value.legal_versions | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| legal_versions.artist_agreement | string | platform_settings | value.legal_versions.artist_agreement | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| legal_versions.auction_terms | string | platform_settings | value.legal_versions.auction_terms | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| legal_versions.collector_terms | string | platform_settings | value.legal_versions.collector_terms | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| legal_versions.intermediary_agreement | string | platform_settings | value.legal_versions.intermediary_agreement | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| legal_versions.terms | string | platform_settings | value.legal_versions.terms | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| legal_versions.tscheck_legal_12204c | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_435826 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_47ffea | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_510869 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_5d1fa0 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_7948d7 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_7a9de8 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_908870 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_a6dc1e | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_a7663c | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_b4b9f6 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_e7d6ee | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_legal_fc6dd4 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_policy_1794480067331 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_policy_1794480263830 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_policy_1794480369032 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_policy_1794481243247 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.tscheck_policy_1794481303057 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_062efa | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_09dc55 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_1ce01a | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_1e4c32 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_2a0953 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_4ab4f2 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_4c6a15 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_58c522 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_5f4f31 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_6762f3 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_68b4b8 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_77013b | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_8156c0 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_83ded2 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_8d76af | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_94a471 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_968492 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_a203e9 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_bd518e | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_bed070 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_c01e20 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_d3df81 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_dde9c6 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_def63c | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_e73b5e | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_eccf05 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_f04a78 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_f5d0a8 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| legal_versions.v2test_fa38e8 | string | — | — | — | none | embedded QA key | must not migrate | discard |
| number | string | platform_settings | value.number | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| platform_commission_pct | number | platform_settings | value.platform_commission_pct | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| privacy_note | string | platform_settings | value.privacy_note | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| published_at | string | platform_settings | value.published_at | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| published_by | string | platform_settings | value.published_by | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| sections | array | platform_settings | value.sections | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| sections[] | object | platform_settings | value.sections[] | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| sections[].enabled | boolean | platform_settings | value.sections[].enabled | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| sections[].key | string | platform_settings | value.sections[].key | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| sections[].limit | number | platform_settings | value.sections[].limit | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| sections[].title | string | platform_settings | value.sections[].title | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| supported_countries | array | platform_settings | value.supported_countries | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| supported_countries[] | string | platform_settings | value.supported_countries[] | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| updated_at | string | platform_settings | value.updated_at | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |
| updated_by | string | platform_settings | value.updated_by | jsonb | preserve key path | none | allow-listed setting; secrets forbidden | preserve-json |

## taxonomy_terms

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| active | boolean | taxonomies | is_active | boolean | copy | none | type, length and nullability checks | ready |
| created_at | string | taxonomies | created_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | ready |
| description | string | taxonomies | description | text | copy | none | type, length and nullability checks | ready |
| id | string | taxonomies | source_record_id | text | lookup emergent_staging.id_map; never cast source text to uuid | none | type, length and nullability checks | extend |
| image | string | taxonomies | image_url | text | copy | none | HTTPS; asset-manifest match; rights/approval gate | extend |
| kind | string | taxonomies | taxonomy_type | text | copy | none | type, length and nullability checks | ready |
| name | string | taxonomies | label | text | copy | none | type, length and nullability checks | ready |
| nav | string | taxonomies | navigation_group | text | copy | none | type, length and nullability checks | extend |
| order | number | taxonomies | sort_order | integer | copy | none | type, length and nullability checks | ready |
| rule | null/object | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.auction | boolean | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.emerging_months | number | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.featured | boolean | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.max_price | number | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.min_price | number | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.new_days | number | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.styles | array | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.styles[] | string | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.subjects | array | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| rule.subjects[] | string | taxonomies | rule | jsonb | copy | none | type, length and nullability checks | extend |
| slug | string | taxonomies | code | text | copy | none | type, length and nullability checks | ready |
| updated_at | string | taxonomies | updated_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | ready |

## users

| Source field | Observed type | Target table | Target column/path | Target type | Identifier transformation | Relationship | Validation | Status |
|---|---|---|---|---|---|---|---|---|
| email | string | auth.users | verified identity lookup only | text | copy | FK only after referenced source id resolves | normalize for comparison; do not grant identity/role from email alone | hold |
| email_verified | boolean | auth.users | verification gate only | boolean | copy | none | normalize for comparison; do not grant identity/role from email alone | hold |
| env | string | profiles | metadata.source_env | jsonb | copy | none | type, length and nullability checks | hold |
| last_login | string | profiles | last_seen_at | timestamptz | ISO-8601 => timestamptz UTC | none | type, length and nullability checks | hold |
| name | string | profiles | display_name | text | copy | none | type, length and nullability checks | hold |
| role | string | user_roles | role | tra_role | copy | none | type, length and nullability checks | hold |
| user_id | string | profiles/user_roles | auth user mapping | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| watchlist | array | auction_watchlists | lot_id | uuid | lookup emergent_staging.id_map; never cast source text to uuid | FK only after referenced source id resolves | type, length and nullability checks | hold |
| watchlist[] | string | auction_watchlists | lot_id | uuid | copy | FK only after referenced source id resolves | type, length and nullability checks | hold |

## Migration status definitions

| Status | Meaning |
|---|---|
| ready | Existing target structure can hold the value after validation and ID resolution. |
| extend | Additive column or table in the draft migration is required. |
| normalize | Array/object becomes related rows with foreign keys. |
| preserve-json | Allow-listed platform configuration remains structured JSON under a stable setting key. |
| derive | Used to verify or derive authoritative target state; not copied blindly. |
| hold | Retained in staging until identity, legal, ownership or grouping decisions resolve. |
| discard | Proven QA/test residue or redundant denormalized value; documented and excluded. |

## Coverage gate

- Staged collections: **15/15**.
- Staged records: **400/400**.
- Observed source field paths: **319**; every observed path has a row above.
- Database writes: **0**.
