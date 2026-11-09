# Architecture

Next.js Server Components deliver public pages. Browser features are added only where needed. Tailwind and central CSS variables provide design tokens. Supabase SSR clients use cookies; secure mutations pass verified sessions to PostgreSQL RPCs. Zod validates bid requests. SQL transactions own auction time, maximums, winner selection and audit events.

Boundaries: public discovery; identity and permissions; artists and intermediary representation; curation and publication; auctions; enquiries; sales and payment links; certificates; shipping; settlements; legal content; configuration; audit.

Current source intentionally implements a narrow vertical foundation. Remaining domain modules are tracked explicitly, not simulated as operational screens. Add React Hook Form when complex onboarding and submission forms are introduced.

Cloudinary is the required future public media provider. Supabase private Storage is reserved for operational documents. No service-role key is required by the current bid route. Netlify is the intended host, GitHub the intended source remote.
