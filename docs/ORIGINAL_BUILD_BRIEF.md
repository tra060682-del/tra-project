You are a senior full-stack solution architect and software engineer. Build the pilot version of tRA, a curated assisted-commerce platform for original Indian paintings.
1\. Source of truth
Before writing code, locate and read:
`docs/tRA_Pilot_Documentation_Pack_v2.docx`
Treat this document as the primary functional source of truth.
If a requirement in this prompt conflicts with the documentation pack:

1. Follow the documentation pack.
2. Record the conflict in `docs/ASSUMPTIONS_AND_DECISIONS.md`.
3. Do not silently remove or materially change a required workflow.

If the document cannot be read directly, extract its text using an appropriate local library or command-line tool. Do not skip it.
2\. Product objective
tRA is a curated assisted-commerce platform for original Indian paintings.
The pilot will launch in India with approximately 50 curated paintings.
The pilot is not a fully automated marketplace. It must support a controlled, human-assisted sales process involving:

- Public artwork discovery
- Artist onboarding and artwork submission
- Internal curation and pricing
- Buyer enquiries
- Manual payment-link tracking
- Artist-led shipping
- Artist-issued Certificate of Authenticity
- Administrative tracking of the complete sale lifecycle

The architecture must remain flexible enough to evolve later into a full multi-artist marketplace with buyer accounts, automated checkout, integrated payments, commission settlement, logistics integrations, and buyer-uploaded room previews.
Do not build those future capabilities unless explicitly included in the pilot requirements.
3\. Mandatory technology stack
Use only the following primary stack:

- Next.js, using the App Router
- TypeScript with strict mode
- Tailwind CSS
- Supabase PostgreSQL
- Supabase Auth
- Supabase Storage only for private operational documents where appropriate
- Cloudinary for artwork and public-facing media images
- Netlify for hosting
- GitHub for version control

Use:

- Server Components by default
- Client Components only where browser interaction requires them
- Server Actions or route handlers for secure mutations
- Zod for request and form validation
- React Hook Form for complex forms
- Supabase SSR-compatible authentication
- Database migrations stored in the repository

Do not introduce another database, authentication provider, CMS, payment gateway, or hosting platform.
4\. Core design principles
Apply these principles consistently:

1. Keep the pilot operationally simple.
2. Keep the architecture modular and scalable.
3. Do not hardcode categories, styles, mediums, subjects, commissions, support details, legal content, workflow statuses, rejection reasons, or other configurable business data where avoidable.
4. Store configurable content in database-backed master or settings tables.
5. Use role-based access control.
6. Enforce data security with Supabase Row Level Security, not only frontend route checks.
7. Preserve a clear audit history for important status and administrative changes.
8. Separate artwork submission data from the final published listing data where useful.
9. Do not treat an artist-submitted price as the final selling price.
10. Do not represent tRA as the issuer of the Certificate of Authenticity.
11. Do not make the website look like a generic e-commerce template.
12. Build reusable domain modules rather than one large collection of tightly coupled pages.
13. Use soft deletion or archival for important business records rather than destructive deletion.
14. Use Indian currency formatting and India-oriented contact/address structures.
15. Use accessible, mobile-responsive interfaces.

5) User roles
   Implement the following pilot roles:
   5.1 Public visitor
   Can:

- Browse published artwork
- Search and filter artwork
- View artwork details
- View artist public profiles where published
- Read configurable informational and legal pages
- Submit an artwork-specific buyer enquiry
- Submit a general enquiry

Does not require an account.
5.2 Artist
Can:

- Register
- Log in and log out
- Reset password
- Submit an artist onboarding request
- Maintain draft onboarding information
- Accept required legal documents online
- View acceptance history
- Upload artwork details and images
- Save artwork submissions as drafts
- Submit artworks for review
- Accept an artwork-specific declaration before submission
- View artwork status
- View admin remarks that are intended to be shared with the artist
- Correct and resubmit returned submissions
- View sale, certificate, shipping, and settlement tasks relevant to their own artworks
- Upload the artist-signed Certificate of Authenticity
- Enter artist-led shipment details where enabled

Artists must only access their own private records.
5.3 Admin
Can:

- Review and manage artist onboarding requests
- Approve, reject, suspend, or request changes from artists
- Review legal-document acceptance
- Review artwork submissions
- Request changes, approve, reject, archive, or publish artworks
- Classify artworks
- Set final listing prices
- Configure commissions or commercial terms without hardcoding
- Manage public listing content
- Track buyer enquiries
- Convert qualified enquiries into sale records
- Record manual payment links
- Track payment status
- Track artwork reservation and sale status
- Track certificate status
- Track artist-led shipping
- Track delivery
- Track settlement status
- Add internal notes and artist-visible remarks
- Manage categories and other master data
- Manage support, contact, legal, and platform settings
- View audit events and status histories

Use a proper admin role. Do not rely on checking whether an email address matches a hardcoded value.
6\. Required pilot modules
6.1 Public website
Create a polished, premium, editorial-style art platform.
Required pages:

- Home
- Browse all artworks
- Artwork detail
- Artist public profile
- About tRA
- How it works
- For artists
- Contact
- General enquiry
- Configurable legal pages
- Privacy policy
- Terms of use
- Artist terms or artist agreement where publicly applicable
- Authentication pages
- Appropriate empty, error, not-found, and success states

Home page sections should be database-driven where practical and may include:

- Hero section
- Featured artworks
- Newly added artworks
- Curated collections
- Featured artists
- Editorial or trust content
- How assisted purchase works
- Artist invitation
- Enquiry call to action

Artwork browsing should support configurable filters such as:

- Category
- Medium
- Style
- Subject
- Orientation
- Price range
- Artist
- Availability
- Size range
- Featured status

Use URL query parameters for public filters so views are shareable.
6.2 Artwork detail page
Include:

- Artwork title
- Artist name
- Main image
- Additional images
- Optional styled-room mockup images
- Medium
- Materials
- Dimensions
- Orientation
- Year
- Description
- Story or inspiration
- Category, style, and subject
- Framing information
- Signature information
- Edition information where applicable
- Location or shipping origin at an appropriate level
- Display price
- Availability
- Certificate information
- Shipping explanation
- Enquiry call to action
- Related artworks

Do not expose private artist contact information.
Use responsive Cloudinary transformations and appropriate image optimisation.
6.3 Artist Dashboard Lite
Create a protected `/artist` area.
Required sections:

- Dashboard overview
- Onboarding profile
- Legal documents and acceptances
- Artwork submissions
- New artwork submission
- Artwork submission detail
- Admin remarks and status history
- Certificate tasks
- Shipping tasks
- Settlement-status view
- Artist account settings

Artist onboarding should support:

- Draft
- Submitted
- Under review
- Changes requested
- Approved
- Rejected
- Suspended

Artist profile fields should be configurable and based on the documentation pack, but should generally support:

- Legal name
- Display name
- Biography
- Artist statement
- Email
- Phone
- Address
- City
- State
- Postal code
- Country
- Website
- Social links
- Identity or tax-document references where required
- Profile image
- Supporting documents
- Admin review status
- Admin remarks

Sensitive documents must not be publicly accessible.
6.4 Artwork submission workflow
Artwork submissions should support:

- Draft
- Submitted
- Under review
- Changes requested
- Approved
- Rejected
- Published
- Unpublished
- Reserved
- Sold
- Archived

An artwork submission should generally capture:

- Artist
- Internal reference
- Title
- Description
- Story or inspiration
- Year created
- Medium
- Surface or material
- Category
- Style
- Subject
- Dimensions
- Dimension unit
- Orientation
- Weight where required
- Framed or unframed status
- Framing details
- Signature details
- Original or edition status
- Edition information
- Artist expected price
- Taxes or inclusions where relevant
- Shipping origin
- Packaging information
- Certificate availability
- Artwork condition
- Main image
- Additional detail images
- Optional styled-room images
- Artist declaration acceptance
- Submission timestamp
- Admin remarks
- Review status

Artwork media should have:

- Media type
- Cloudinary public ID
- Secure URL
- Width
- Height
- Format
- Sort order
- Alt text
- Primary-image flag
- Optional moderation or approval status

The artist must accept an artwork-wise declaration before final submission.
Store:

- Declaration version
- Acceptance timestamp
- User ID
- Artwork ID
- IP address where practical and lawful
- User-agent metadata where practical
- A snapshot or hash of the accepted declaration content

6.5 Admin Dashboard
Create a protected `/admin` area.
Required sections:

- Dashboard overview
- Artist review queue
- Artist detail and review
- Artwork review queue
- Artwork detail and review
- Published artwork management
- Buyer enquiries
- Enquiry detail
- Sales
- Sale detail
- Payment-link tracking
- Certificate tracking
- Shipping tracking
- Settlement tracking
- Taxonomy and master-data management
- Legal-document management
- Platform settings
- Content settings
- Audit log

Admin dashboard metrics may include:

- Pending artists
- Pending artwork submissions
- Published artworks
- Available artworks
- Open enquiries
- Qualified enquiries
- Awaiting payment
- Reserved artworks
- Awaiting certificate
- Awaiting shipment
- In transit
- Delivered
- Awaiting settlement
- Completed sales

All important admin actions must be validated server-side and recorded in an audit log.
6.6 Buyer enquiry flow
No buyer account or automated checkout is required in the pilot.
Support:

- Artwork-specific enquiry
- General enquiry
- Buyer name
- Email
- Phone
- City
- State
- Country
- Preferred contact method
- Buyer message
- Consent checkbox
- Artwork reference where applicable
- Source or campaign metadata where available
- Spam protection compatible with Netlify or a lightweight provider
- Success acknowledgement

Enquiry statuses should be configurable and may include:

- New
- Contact attempted
- Contacted
- Qualified
- Negotiating
- Payment link sent
- Converted
- Closed
- Spam
- Not proceeding

Store enquiry notes separately from the public buyer message.
Support assignment to an admin user.
6.7 Assisted sale and manual payment-link tracking
Do not integrate automated payment processing in the pilot.
An admin must be able to:

- Create a sale from an enquiry
- Associate the buyer, artist, and artwork
- Record agreed selling price
- Record discount
- Record taxes
- Record shipping charge
- Record gross amount
- Record commission rule or commission snapshot
- Record artist settlement amount
- Reserve the artwork
- Store a manually generated payment-link URL
- Record payment-link provider
- Record link creation date
- Record link expiry
- Record payment status
- Record transaction or payment reference
- Record paid date
- Add payment notes

Payment statuses may include:

- Not requested
- Link pending
- Link sent
- Payment pending
- Paid
- Partially paid
- Failed
- Expired
- Refunded
- Cancelled

Never expose private payment tracking data publicly.
Do not automatically mark a sale as paid based only on a frontend action.
6.8 Certificate of Authenticity workflow
The Certificate of Authenticity is issued and signed by the artist.
tRA:

- Provides a certificate template
- Generates or assigns a reference ID
- Tracks certificate preparation
- Stores the digital copy
- Checks whether required fields are complete
- Shares the final digital copy with the buyer
- Maintains certificate status and audit history

tRA must not be presented as the certificate issuer.
Support statuses such as:

- Not started
- Reference assigned
- Template shared
- Awaiting artist
- Uploaded by artist
- Under completeness check
- Changes requested
- Complete
- Shared with buyer

The certificate record should support:

- Sale
- Artwork
- Artist
- Certificate reference
- Template version
- Artist-supplied certificate file
- Artist-signed date
- Upload date
- Completeness-check status
- Checked by
- Checked date
- Admin remarks
- Artist-visible correction request
- Buyer-shared date
- File version history where practical

Store certificate files privately. Generate authorised, time-limited access when the buyer copy needs to be shared.
6.9 Artist-led shipping workflow
The artist is responsible for physical dispatch in the pilot.
Support:

- Shipping pending
- Awaiting artist confirmation
- Packaging in progress
- Ready to dispatch
- Dispatched
- In transit
- Delivery attempted
- Delivered
- Exception
- Returned
- Cancelled

Track:

- Sale
- Artwork
- Artist
- Shipping origin
- Buyer delivery details with restricted access
- Courier
- Tracking number
- Tracking URL
- Dispatch date
- Estimated delivery date
- Delivered date
- Packaging notes
- Shipment notes
- Proof-of-dispatch document or image
- Status history
- Admin verification

Public users must never access buyer delivery data.
6.10 Artist settlement tracking
Do not build automated payouts in the pilot.
Track:

- Sale
- Artist
- Gross selling price
- Commission type
- Commission rate or fixed amount snapshot
- Commission amount
- Taxes or deductions
- Shipping treatment
- Net settlement amount
- Settlement due date
- Settlement status
- Settlement reference
- Settlement date
- Admin notes

Statuses may include:

- Not calculated
- Pending delivery
- Pending return window
- Ready for settlement
- Processing
- Settled
- On hold
- Disputed
- Cancelled

Artists may view their own settlement status and relevant amounts but may not edit admin financial calculations.
7\. Configurable master data
Create database-backed administration for at least:

- Artwork categories
- Mediums
- Styles
- Subjects
- Materials or surfaces
- Orientations
- Dimension units
- Artwork statuses
- Artist statuses
- Enquiry statuses
- Sale statuses
- Payment statuses
- Certificate statuses
- Shipping statuses
- Settlement statuses
- Rejection reasons
- Change-request reasons
- Commission rules
- Legal-document types
- Support contact details
- Social links
- Platform settings
- Public content blocks
- Homepage featured collections

Master-data records should generally support:

- ID
- Code
- Display label
- Description
- Sort order
- Active flag
- Created timestamp
- Updated timestamp

Do not make status transitions depend solely on editable display labels. Use stable codes or enums internally, while allowing labels and descriptions to be configured.
8\. Suggested database domains
Design a normalised Supabase PostgreSQL schema. Refine table names after reading the documentation pack.
At minimum consider:

- `profiles`
- `user_roles`
- `artist_profiles`
- `artist_onboarding_requests`
- `artist_documents`
- `legal_documents`
- `legal_document_versions`
- `legal_acceptances`
- `artworks`
- `artwork_submissions`
- `artwork_media`
- `artwork_declarations`
- `artwork_status_history`
- `artist_status_history`
- `categories`
- `mediums`
- `styles`
- `subjects`
- `materials`
- `orientations`
- `collections`
- `collection_artworks`
- `buyer_enquiries`
- `enquiry_notes`
- `enquiry_status_history`
- `buyers`
- `sales`
- `sale_status_history`
- `payment_links`
- `payment_status_history`
- `certificates`
- `certificate_files`
- `certificate_status_history`
- `shipments`
- `shipment_status_history`
- `settlements`
- `settlement_status_history`
- `commission_rules`
- `platform_settings`
- `content_pages`
- `content_blocks`
- `admin_notes`
- `audit_events`

Use UUID primary keys.
Use:

- `created_at`
- `updated_at`
- `created_by`
- `updated_by`

where appropriate.
Use immutable snapshots for commercial data on a sale. A future change to a commission rule must not alter an already-created sale calculation.
Use proper foreign keys, check constraints, unique constraints, and indexes.
Add a documented updated-at trigger where appropriate.
9\. Authentication and security
Implement Supabase Auth with:

- Email and password registration
- Email verification
- Password reset
- Secure session handling for Next.js
- Protected artist and admin layouts
- Server-side role verification
- Row Level Security

RLS requirements:

- Public users can read only published and active public records.
- Artists can read and update only permitted fields in their own artist profile.
- Artists can access only their own artwork submissions, declarations, certificate tasks, shipment tasks, and settlement views.
- Artists cannot approve themselves or their artwork.
- Artists cannot set the final public price.
- Artists cannot access other artists’ records.
- Artists cannot access internal admin notes.
- Admins can access administrative records according to their role.
- Service-role credentials must never be exposed to the browser.
- Private documents must not have public URLs.
- Buyer personal data must be restricted to authorised administrators and the minimum artist shipping view needed for fulfilment.

Implement route protection in addition to RLS, but never use route protection as a replacement for RLS.
Add input validation, output escaping, secure error handling, and safe file-upload validation.
Do not log secrets, full identity documents, payment details, or unnecessary personal information.
10\. Cloudinary media architecture
Use Cloudinary for:

- Artwork main images
- Artwork detail images
- Artist public profile images
- Optional styled-room mockups
- Public editorial images

Implement:

- Signed uploads or secure upload presets
- File type restrictions
- File size restrictions
- Image dimension validation
- Transformation-based responsive rendering
- Thumbnail transformations
- Web-optimised formats
- Metadata storage in Supabase
- Deletion or archival handling
- Image ordering
- Alt text
- Primary-image selection

Separate media types:

- `artwork_original`
- `artwork_detail`
- `styled_room_mockup`
- `artist_profile`
- `editorial`

Styled-room mockups are optional in the pilot. The data model and UI must support them without requiring them.
Keep future buyer-uploaded room images possible through a separate future media purpose or table, but do not build that buyer feature now.
11\. Legal-document acceptance
Legal content must be versioned.
An administrator should be able to:

- Create a legal document
- Add a new version
- Set effective date
- Publish or retire a version
- Mark whether artist acceptance is mandatory
- View acceptance records

Artist acceptance must capture:

- User
- Artist
- Legal document
- Version
- Acceptance timestamp
- Acceptance statement
- Content hash or snapshot
- IP address where practical
- User agent where practical

Do not overwrite prior accepted versions.
An artist should be prevented from completing onboarding or submitting artwork when a mandatory current document has not been accepted, subject to documentation-pack rules.
12\. Workflow and status-transition controls
Create explicit service-layer functions for important transitions.
Examples:

- Submit artist onboarding
- Request artist changes
- Approve artist
- Reject artist
- Submit artwork
- Request artwork changes
- Approve artwork
- Publish artwork
- Unpublish artwork
- Create sale from enquiry
- Reserve artwork
- Record payment link
- Confirm payment
- Request certificate
- Approve certificate completeness
- Record dispatch
- Confirm delivery
- Mark settlement ready
- Record settlement

Each transition must:

1. Verify the authenticated user.
2. Verify the user’s role.
3. Verify ownership where relevant.
4. Verify that the current status permits the transition.
5. Validate required fields.
6. Update the main record transactionally.
7. Insert status history.
8. Insert an audit event.
9. Return a typed result.

Prevent invalid transitions such as:

- Publishing an unapproved artist’s artwork
- Publishing artwork without approved media or final price
- Selling an unavailable artwork
- Reserving one artwork for multiple active sales
- Marking a certificate complete without a certificate file
- Settling before the required delivery or approval condition
- Allowing artists to change an artwork while it is sold without an admin-controlled process

13. User experience and visual direction
    Create a premium Indian-art visual identity.
    The design should feel:

- Curated
- Sophisticated
- Editorial
- Warm
- Trustworthy
- Contemporary
- Art-led rather than transaction-led

Avoid:

- Generic marketplace cards
- Excessive gradients
- Overcrowded dashboards
- Bright discount-oriented e-commerce styling
- Fake scarcity
- Unsupported claims
- Placeholder lorem ipsum in completed screens

Use:

- Strong artwork imagery
- Generous whitespace
- Refined typography
- Restrained animation
- Clear status badges
- Accessible contrast
- Keyboard-accessible forms and controls
- Responsive layouts
- Mobile-first artist workflows

Keep visual tokens centralised in Tailwind and CSS variables.
14\. Recommended application structure
Use a domain-oriented structure similar to:

```
src/
  app/
    (public)/
    (auth)/
    artist/
    admin/
    api/
  components/
    ui/
    public/
    artist/
    admin/
    forms/
  features/
    auth/
    artists/
    artworks/
    enquiries/
    sales/
    payments/
    certificates/
    shipping/
    settlements/
    legal/
    configuration/
    audit/
  lib/
    auth/
    supabase/
    cloudinary/
    validation/
    permissions/
    formatting/
    errors/
  server/
    actions/
    services/
    repositories/
    queries/
  types/
  config/
supabase/
  migrations/
  seed.sql
  tests/
docs/
tests/
```

You may improve the structure, but keep domain boundaries clear.
Do not create a premature microservices architecture.
15\. API and server-side implementation
Use a typed service layer.
Avoid placing complex business logic directly inside React components.
For every major domain, separate:

- Validation
- Authorisation
- Database access
- Workflow logic
- Presentation

Use route handlers where required for:

- Cloudinary signatures or upload coordination
- Secure webhooks in the future
- Public enquiry submissions
- Private document access
- Netlify-compatible server functionality

Return consistent error structures.
Create a central application error model containing:

- Error code
- Safe user message
- Internal context
- HTTP status where applicable

Do not expose database or stack traces to users.
16\. Auditability
Create an `audit_events` model for important actions.
Capture:

- Actor user ID
- Actor role
- Action code
- Entity type
- Entity ID
- Previous state where appropriate
- New state where appropriate
- Metadata
- Timestamp
- Request or correlation ID where practical

Audit at least:

- Artist submission
- Legal acceptance
- Artist approval or rejection
- Artwork submission
- Artwork approval, rejection, publication, and pricing
- Enquiry reassignment or status change
- Sale creation
- Payment status changes
- Certificate status changes
- Shipping status changes
- Settlement status changes
- Configuration changes

Do not allow normal users to edit audit records.
17\. Seed data
Create safe, non-production seed data for local development:

- One admin user setup guide
- Two sample artists
- Around 10 sample artwork records
- Categories
- Mediums
- Styles
- Subjects
- Orientations
- Workflow statuses
- Commission examples
- Legal-document examples
- Public content examples
- Buyer enquiries in different statuses
- One sample sale lifecycle

Do not include real identity documents or real buyer personal data.
The pilot must be able to support approximately 50 initial paintings without code changes.
18\. Testing requirements
Set up meaningful automated tests.
Include:
Unit tests

- Validation schemas
- Price and commission calculations
- Status-transition rules
- Role and ownership permissions
- Certificate completeness rules
- Settlement calculation logic

Integration tests

- Artist onboarding submission
- Artist legal acceptance
- Artwork submission
- Admin approval
- Artwork publication
- Public enquiry
- Sale creation
- Manual payment-link recording
- Certificate upload and completeness check
- Shipment status update
- Settlement status update

End-to-end tests
Use Playwright for critical journeys:

1. Artist registers and submits onboarding.
2. Admin approves artist.
3. Artist submits artwork and declaration.
4. Admin requests changes.
5. Artist resubmits.
6. Admin approves, prices, and publishes.
7. Visitor submits enquiry.
8. Admin qualifies enquiry and creates sale.
9. Admin records payment link and payment.
10. Artist uploads signed certificate.
11. Admin checks and shares certificate.
12. Artist records shipment.
13. Admin records delivery and settlement.

Do not rely only on snapshot tests.
19\. Documentation deliverables
Create:

- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/DATABASE_SCHEMA.md`
- `docs/RLS_AND_SECURITY.md`
- `docs/WORKFLOWS.md`
- `docs/DEPLOYMENT_NETLIFY.md`
- `docs/CLOUDINARY_SETUP.md`
- `docs/SUPABASE_SETUP.md`
- `docs/ADMIN_GUIDE.md`
- `docs/ARTIST_GUIDE.md`
- `docs/TESTING.md`
- `docs/ASSUMPTIONS_AND_DECISIONS.md`
- `.env.example`

The README must include:

- Prerequisites
- Local setup
- Supabase setup
- Migration commands
- Seed commands
- Cloudinary configuration
- Netlify configuration
- Test commands
- Build commands
- Admin-user bootstrap instructions
- Known pilot limitations

Never place real credentials in the repository.
20\. Deployment requirements
Prepare the project for Netlify deployment.
Ensure:

- Next.js features used are supported by the selected Netlify runtime.
- Environment variables are documented.
- Supabase browser and server clients are configured correctly.
- Cloudinary secrets are server-only.
- Production build succeeds.
- Type checking succeeds.
- Linting succeeds.
- Automated tests succeed.
- Database migrations are reproducible.
- Public routes have appropriate metadata.
- Sitemap and robots configuration are included.
- Error monitoring integration is documented as an optional production enhancement.

21. Pilot exclusions
    Unless the documentation pack explicitly states otherwise, do not build:

- Automated payment gateway checkout
- Automated payment reconciliation
- Automated artist payouts
- Buyer accounts
- Shopping cart
- Multi-item checkout
- Auction functionality
- Bidding
- Buyer reviews
- Direct buyer-to-artist messaging
- Integrated courier booking
- Automatic shipping-price calculation
- AI-generated artwork valuation
- Buyer-uploaded room or wall preview
- Native mobile applications
- Multi-currency checkout
- International tax automation
- Full marketplace self-service
- NFT or blockchain certificate functionality

The architecture may anticipate these features, but pilot screens and workflows must not pretend they are operational.
22\. Implementation sequence
Work in controlled phases.
Phase 1: Analysis and foundation
Before implementing full features:

1. Read the documentation pack.
2. Produce `docs/REQUIREMENTS_TRACEABILITY.md`.
3. Produce `docs/ASSUMPTIONS_AND_DECISIONS.md`.
4. Define application modules.
5. Define user roles and permission matrix.
6. Define data model.
7. Define status-transition matrix.
8. Define RLS approach.
9. Define routes.
10. Define environment-variable requirements.

Then implement:

- Next.js setup
- TypeScript strict configuration
- Tailwind design tokens
- Supabase clients
- Authentication foundation
- Shared layouts
- Error handling
- Database migrations
- Seed framework

Phase 2: Public catalogue
Implement:

- Public layout
- Home page
- Artwork catalogue
- Filters
- Artwork detail
- Artist profile
- Content pages
- Enquiry forms

Phase 3: Artist Dashboard Lite
Implement:

- Artist authentication
- Onboarding
- Legal acceptance
- Artwork drafts
- Image upload
- Artwork declaration
- Submission
- Status and admin remarks
- Certificate and shipping tasks

Phase 4: Admin Dashboard
Implement:

- Artist review
- Artwork review
- Classification
- Final pricing
- Publishing
- Master data
- Legal content
- Settings
- Audit history

Phase 5: Assisted commerce operations
Implement:

- Enquiry management
- Sale creation
- Reservation
- Manual payment-link tracking
- Certificate workflow
- Shipping workflow
- Settlement tracking

Phase 6: Hardening
Complete:

- RLS verification
- Validation
- Automated testing
- Accessibility review
- Responsive review
- Performance review
- Build verification
- Netlify deployment documentation
- Operational guides

23. Required output behaviour
    Do not attempt to generate the entire application as one unreviewable code dump.
    Start by inspecting the repository and documentation.
    Then provide:

1) Summary of interpreted scope
2) Requirements gaps or assumptions
3) Proposed architecture
4) Proposed route map
5) Proposed database entities
6) Role and permission matrix
7) Workflow/status-transition matrix
8) Implementation plan
9) Exact files to be created or changed

After that, implement Phase 1 completely.
At the end of each phase:

- Run formatting
- Run linting
- Run TypeScript type checking
- Run tests
- Run the production build
- Fix failures before declaring the phase complete
- Update documentation
- Summarise files changed
- Summarise unresolved issues
- Commit changes in a logical Git commit if Git access is available

Do not claim a feature is complete unless its UI, server logic, database migration, authorisation, validation, and basic tests are all implemented.
24\. Code-quality rules

- TypeScript strict mode must remain enabled.
- Do not use `any` unless documented and unavoidable.
- Prefer typed domain objects and Zod-inferred types.
- Avoid duplicate business rules across UI and server code.
- Never trust browser-supplied role, price, status, artist ID, or ownership data.
- Keep server-only code out of client bundles.
- Use transactions for multi-record workflow updates.
- Use semantic naming.
- Keep components reasonably small.
- Add comments for business reasoning, not obvious syntax.
- Do not leave critical workflows as TODO placeholders.
- Do not use mock data in production paths.
- Do not expose unpublished artwork through metadata, search, or direct queries.
- Do not expose artist-private or buyer-private information.
- Do not allow concurrent sale creation to oversell an artwork.
- Preserve historical commercial and legal snapshots.

Begin by reading `docs/tRA_Pilot_Documentation_Pack_v2.docx`, inspecting the current repository, and producing the Phase 1 analysis documents before modifying application code.